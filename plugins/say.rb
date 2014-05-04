require 'cinch'

require_relative '../modules/speech.rb'

class Say
  include Cinch::Plugin
  include Speech

  match /(say) (.+)/, method: :execute

  def execute( m, name, word )
    return if not m.useCommands?

    word, chainlen = self.sayArgParser word

    # Gets our word and chainlen in the right forms
    word, chainlen = self.prepare( m, word, chainlen.to_i, ( name == "sayl" ) )

    if word == nil
      return
    end

    # Chains off of our word with n=chainlen
    res = Chain.new m, word, chainlen

    # Return our finalized product
    m.reply res.to_s
  end

  # Sanitizes chainlength to fall into specs
  def prepare( m, word, chainlen, simto )
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

    if simto
      word = "%#{word}%"
      wid = m.getFirst_i "SELECT id FROM words WHERE word SIMILAR TO ? ORDER BY random() LIMIT 1", word
    else
      wid = m.getFirst_i "SELECT id FROM words WHERE word ILIKE ? ORDER BY random() LIMIT 1", word
    end
      
    if wid == nil
      m.reply "I don't know the word: \"#{oword}\""
    end

    return wid, chainlen
  end

end

