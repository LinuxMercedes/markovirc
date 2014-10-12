require 'cinch'

require_relative 'say.rb'

class Log
  include Cinch::Plugin

  set :prefix, /^[^!]/
  match //, method: :execute

  CHANNEL=0
  PM=1
  DIRECT=2

  @msg = nil

  def execute( m )
    @msg = m

    # Handle our logs, creates m.sentence, and stores chains as needed
    self.logHandle

    # Randomly speaks when it's appropriate
    self.speakRandom
  end

  """
  First get chanid, then the userid. Check to see if this is a known source, if not
  add it, then hook into chains.
  """
  def logHandle( )
    chanid = 0
    userid = 0
    sourceid = 0

    # Sentences store internally for use in RandomSpeak and other plugins on this thread
    #sentences = sever @msg.message
    #@msg.sentence = ( Sentence.new @msg, sentences )

    # We don't log when we're pinged
    return if @msg.canRespond?

    #### Store our channel if it doesn't exist, otherwise get it
    chanid = @msg.getFirst "SELECT 1 FROM channels WHERE name = ?", @msg.channel.name
    if chanid == nil 
      chanid = @msg.getFirst "INSERT INTO channels (name) VALUES (?) RETURNING id", @msg.channel.name
    end

    #### Get our UserID, store if it doesn't exist
    userid = @msg.getFirst "SELECT id FROM users WHERE hostmask = ?", (@msg.user.name + "@" + @msg.user.host)
    if userid == nil
      userid = @msg.getFirst "INSERT INTO users (hostmask) VALUES (?) RETURNING id", (@msg.user.name + "@" + @msg.user.host)
    end

    #### Get SourceID, which uniquely identifies a user in a channel
    sourceid = @msg.getFirst "SELECT id FROM sources WHERE channelid = ? AND userid = ?", [chanid, userid]
    if sourceid == nil
      sourceid = @msg.getFirst "INSERT INTO sources (channelid,userid,type) VALUES (?,?,?) RETURNING id", [chanid, userid, CHANNEL]
    end

    print "\n\nsourceid: ", sourceid, "\n userid: ", userid, "\nchainid: ", chanid, "\n\n"

    #### Store our textid
    # Store our source text for future rehashing / referencing
    @msg.textid = @msg.getFirst "INSERT INTO text (sourceid, time, text) VALUES (?,?,?) RETURNING id", [sourceid, @msg.time.to_i, @msg.message]
  end

  """
  speakRandom

  Wraps speak() going from someone's last spoken line. It'll only go through if a random probability is met,
  and in the future may get thrown out for various criteria described in the example config file. It somewhat
  randomly chooses a word from the text provided by ranking all words by their frequency of occurance and choosing
  randomly from top rarest 45%**. This knocks out a bunch of pronouns and common verbs, which are typically boring... 
  this is also incredibly rough for the internet, as grammar gets the axe online. 

  ** The Secret Life of Pronouns, pg 25
  """
  def speakRandom( )
    if Random.rand > $bot.set.logic.replyrate and not @msg.canRespond?
      return
    end

    return

    words = []

    # Strip punctuation
    @msg.sentence.words.each do |word|
      if word.text !~ /^[:,"\.!?]+$/
        words << word
      end
    end

    # Drop our name if we were pinged and the first word matches
    if words.first.text.match $bot.nick
      words.slice! 0
    end

    # Get a corresponding array of the number of chains that mention this wid at any point
    counts = []
    words.each do |word|
      counts << ( @msg.getFirst "SELECT count(*) FROM chains WHERE wordid = ? OR nextwordid = ?", [ word.wid, word.wid ] ).to_i
    end

    # Drop words with <= one occurence, this means it's brand new and not good fodder.
    i = 0
    counts.each do |num|
      if num <= 1
        counts.delete_at i
        words.delete_at i
      else
        i += 1
      end
    end

    if words.length <= 0
      return
    end

    # Sort each word by its appropriate count. This nasty bit sorts words from least occurences to most. 
    words = words.sort { |x, y| counts[words.index( x )] <=> counts[words.index( y )] }

    # Remove the last (most occuring) 55% of the phrase, rounded down so that there's an extra 
    words = words[0..(words.length*0.45).ceil]

    # Hacky say wrapper
    $bot.handlers.each do |handler|
      if handler.event == :message and "!say w".match handler.pattern.to_r
        handler.call @msg, ["say", words[Random.rand(0..(words.size-1))].text ], [] # this is a bit slower since it'll look it up twice, but saves time
        break
      end
    end
  end 
end
