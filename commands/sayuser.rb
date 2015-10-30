require 'cinch'
require_relative '../modules/regexparser.rb'
require_relative '../modules/speech.rb'

class SayUser
  include Cinch::Plugin
  include Speech
  include RegexParser

  match /sayu ([^\s]+) (.+)/, method: :execute

  def execute( m, mask, word )
    return if not m.useCommands?
    m.setup 

    word, chainlen, type, regexinfo = self.sayArgParser word

    # Gets our word and chainlen in the right forms
    word, chainlen = self.prepare( m, word, chainlen, type, regexinfo )

    if word == nil or word <= 0
      return
    end

    # Chains off of our word with n=chainlen
    res = Chain.new m, word
    res.extracriteria = "AND tid IN (SELECT id " \
      + "FROM text WHERE sourceid IN (SELECT id FROM sources WHERE userid IN (" \
      + "SELECT id FROM users WHERE "

    regexinfo = parseRegex mask
    if regexinfo == nil
      res.extracriteria += "hostmask LIKE '#{m.escape_string(mask)}%')))"
    else
      res.extracriteria += "hostmask #{regexinfo[:op]} '#{m.escape_string(regexinfo[:regex])}')))"
    end

    check = res.extracriteria.gsub /^AND /, ""
    if m.getFirst_i("SELECT count(id) FROM chains WHERE #{check}") == 0
      m.reply "No matches for provided hostmask query"
      return
    end



    res.fill m, chainlen

    # Return our finalized product
    m.reply res.to_s

    self.log m, res
  end

  # Sanitizes chainlength to fall into specs
  def prepare( m, word, chainlen, type, regexinfo )
    xchain = m.bot.set.logic.maxchainlength
    nchain = m.bot.set.logic.minchainlength
    wid = -1
    oword = word
    
    # Rope our chain length into whatever config has it set as
    if not chainlen.is_a? Integer or chainlen <= 0
      chainlen = Random.new.rand nchain..xchain
    elsif chainlen > xchain
      chainlen = xchain
    elsif chainlen < nchain
      chainlen = nchain
    end

    if type == "regex"
      wid = m.getFirst_i_rand( "id", ( "words WHERE word " + regexinfo[:op] + " ?" ), regexinfo[:regex] )
    else
      wid = m.getFirst_i_rand "id", "words WHERE word = ?", word
    end
      
    if wid == nil or wid <= 0
      m.reply "I don't know the word: \"#{oword}\""
    end

    return wid, chainlen
  end

  # We push what we said onto a "stack" so we can draw from it for !src later.
  def log( m, sentence )
    # Prep the sentence so it doesn't keep msg in memory.
    sentence.msg = nil

    # Pop it on our psuedostack
    $bot.logs[m.channel] << sentence  

    if $bot.logs[m.channel].length > $bot.set['history']
      $bot.shift
    end
  end
end

