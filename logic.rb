require_relative 'plugins/say.rb'

# FIXME: Give me a constants file
module TYPES
  CHANNEL=0
  PM=1
  DIRECT=2
end

"""
I'm pretty sure sqlite3 handles this natively
First get chanid, then the userid. Check to see if this is a known source, if not
add it, then plug the text in.
"""
def logHandle( msg )
  chanid = 0
  userid = 0
  sourceid = 0

  sentences = sever msg.message
  
  msg.sentence = ( Sentence.new msg, sentences )

  if msg.canRespond?
    return
  end

  res = msg.getArray "SELECT 1 FROM channels WHERE name = ?", msg.channel.name
  if res.size == 0
    msg.getArray "INSERT INTO channels (name) VALUES (?)", msg.channel.name
  end

  chanid = msg.getFirst "SELECT id FROM channels WHERE name = ?", msg.channel.name

  res = msg.getArray "SELECT 1 FROM users WHERE hostmask = ?", (msg.user.name + "@" + msg.user.host)
  if res.size == 0
    msg.getArray "INSERT INTO users (hostmask) VALUES (?)", (msg.user.name + "@" + msg.user.host)
  end

  userid = msg.getFirst "SELECT id FROM users WHERE hostmask = ?", (msg.user.name + "@" + msg.user.host)

  res = msg.getArray "SELECT 1 FROM sources WHERE channelid = ? AND userid = ?", [chanid, userid]
  if res.size == 0
    msg.getArray "INSERT INTO sources (channelid,userid,type) VALUES (?,?,?)", [chanid, userid, TYPES::CHANNEL]
  end

  sourceid = msg.getFirst "SELECT id FROM sources WHERE userid = ? AND channelid = ?", [userid, chanid]

  msg.getArray "INSERT INTO text (sourceid, time, text) VALUES (?,?,?)", [sourceid, msg.time.to_i, msg.message]

  textid = msg.getFirst "SELECT id FROM text WHERE sourceid = ? AND time = ? AND text = ?", [sourceid, msg.time.to_i, msg.message]
  
  msg.textid = textid

  # Create our chain
  chain msg, textid
end

"""
Chain
Create our chain and throw it into main.chains

We take our base text and split it up into sentences by punctuation.
Next split the sentences by space into a 2d array.
Then replace all words with their word id.
Last create a relation for each word referencing our text.
"""
def chain( msg, textid )
  # Insert our chains
  msg.sentence.each do |sentence|
    sentence.size.times do |i|
      if i != sentence.size-1
        msg.getArray "INSERT INTO chains (wordid,textid,nextwordid) VALUES (?,?,?)", [sentence[i].wid, textid, sentence[i+1].wid]
      else
        msg.getArray "INSERT INTO chains (wordid,textid) VALUES (?,?)", [sentence[i].wid, textid]
      end
    end
  end
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
def speakRandom( msg )
  if Random.rand > $bot.set.logic.replyrate and not msg.canRespond?
    return
  end

  words = []

  # Strip punctuation
  msg.sentence.words.each do |word|
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
    counts << ( msg.getFirst "SELECT count(*) FROM chains WHERE wordid = ? OR nextwordid = ?", [ word.wid, word.wid ] ).to_i
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
      handler.call msg, ["say", words[Random.rand(0..(words.size-1))].text ], [] # this is a bit slower since it'll look it up twice, but saves time
      break
    end
  end
end 
