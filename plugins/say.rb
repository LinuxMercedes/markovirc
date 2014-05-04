require 'cinch'

require_relative '../modules/speech.rb'

class Say
  include Cinch::Plugin
  include Speech

  match /say (.+)/, method: :execute

  def execute( m, word )
    word, chainlen = self.sayArgParser word

    if not isSane? m, word 
      return
    end

    # Gets our word and chainlen in the right forms
    chainlen = prepare m, chainlen.to_i

    # Chains off of our word with n=chainlen
    res = Chain.new m, word, chainlen
    res.fill

    # Return our finalized product
    m.reply res.to_s
  end

end

