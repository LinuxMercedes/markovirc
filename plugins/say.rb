require 'cinch'
require_relative '../modules/regexparser.rb'
require_relative '../modules/speech.rb'

class Say
  include Cinch::Plugin
  include Speech
  include RegexParser

  match /(say[l]?) (.+)/, method: :execute

  def execute( m, name, word )
    return if not m.useCommands?

    word, chainlen, type, regexinfo = self.sayArgParser word

    type = "simto" if name == "sayl" and type != "regex"

    # Gets our word and chainlen in the right forms
    word, chainlen = self.prepare( m, word, chainlen, type, regexinfo )

    if word == nil or word <= 0
      return
    end

    # Chains off of our word with n=chainlen
    res = Chain.new m, word, chainlen

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

    if type == "simto"
      word = "%#{word}%"
      wid = m.getFirst_i_rand "id", "words WHERE word SIMILAR TO ?", word
    elsif type == "regex"
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
      $bot.delete_at 0
    end
  end
end

