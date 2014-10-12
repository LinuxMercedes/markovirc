class RandomSpeech
  include Cinch::Plugin

  set :prefix, /^[^!]/
  match //, method: :execute

  CHANNEL=0
  PM=1
  DIRECT=2

  """
  Wraps speak() going from someone's last spoken line. It'll only go through if a random probability is met,
  and in the future may get thrown out for various criteria described in the example config file. It somewhat
  randomly chooses a word from the text provided by ranking all words by their frequency of occurance and choosing
  randomly from top rarest 45%**. This knocks out a bunch of pronouns and common verbs, which are typically boring... 
  this is also incredibly rough for the internet, as grammar gets the axe online. 

  ** The Secret Life of Pronouns, pg 25
  """
  def execute( msg )
    if Random.rand > $bot.set.logic.replyrate and not msg.canRespond?
      return
    end

    words = []
    sent = sever msg.message

    # Strip punctuation
    sent.each do |word|
      if word !~ /^[:,"\.!?]+$/
        words << word
      end
    end

    # Drop our name if we were pinged and the first word matches
    if words.first.match $bot.nick
      words.slice! 0
    end

    widhash = []
    # Create our block for getting a wid hash
    msg.pool.with do |conn|
      widhash = widHash( words, conn )
    end

    # Get a corresponding array of the number of chains that mention this wid at any point
    counts = []
    wids = widhash.values
    wids.each do |wid|
      counts << ( msg.getFirst "SELECT count(id) FROM chains WHERE wordid = ? OR nextwordid = ?", [ wid, wid ] ).to_i
    end

    # Drop words with <= one occurence, this means it's brand new and not good fodder.
    i = 0
    counts.each do |num|
      if num <= 1
        counts.delete_at i
        wids.delete_at i
      else
        i += 1
      end
    end

    return if wids.size <= 0

    # Sort each word by its appropriate count. This nasty bit sorts words from least occurences to most. 
    wids = wids.sort { |x, y| counts[wids.index( x )] <=> counts[wids.index( y )] }

    # Remove the last (most occuring) 55% of the phrase, rounded down so that there's an extra 
    wids = wids[0..(wids.length*0.45).ceil]

    # Hacky say wrapper
    $bot.handlers.each do |handler|
      if handler.event == :message and "!say w".match handler.pattern.to_r
        handler.call msg, ["say", widhash.key(wids[Random.rand(0..(wids.size-1))]).to_s ], [] # this is a bit slower since it'll look it up twice, but saves code
        break
      end
    end
  end 
end
