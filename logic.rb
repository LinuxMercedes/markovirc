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
  sentences = sever msg.message
  msg.sentence = []

  sentences.each do |sentence|
    msg.sentence << ( Sentence.new msg, sentence )
  end

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
Speak
Pulls a word from our database and starts a chain with it.
"""
def speak( msg, word, chainlen )
  sentence = Sentence.new( msg )

  sentence << word

  # Go to the left, negative
  speakNext msg, sentence, chainlen, -1

  # Now to the right, positive
  speakNext msg, sentence, chainlen, 1

  msg.reply( sentence.join " " )
end

"""
SpeakNext
Helper function for getting the 'next' word. Using dir, it decides which way it is going to
look while iterating through chains. The sentence inputted is an array of wordids
which is added to whilest iterating. 
FIXME: make this a goddamn class
"""
def speakNext( msg, sentence, chainlen, dir )
  # we use our source id and sourceid counter (sid / sidi) to help us emulate native database support for
  #   higher length markov chains. 
  sid = -1
  sidi = -1

  start = sentence.length
  while sentence.length < start+25 
    twid = ( dir <= 0 ? sentence.first.wid : sentence.last.wid ) #thiswid
    res = ""

    if not ( twid.is_a? Fixnum or twid.is_a? Integer or twid.is_a? String ) or twid < 1 #FIXME: Sometimes sentences end up with trailing 0's or -1's. This should never happen. Fix it.
      sentence.clean
      break
    end

    # If we don't already have a source lined up...
    if sid == -1
      if dir <= 0
        res = msg.getArray "SELECT wordid,textid from chains WHERE nextwordid = ? ORDER BY random() LIMIT 1", twid #goin' left, look to the left
      else
        res = msg.getArray "SELECT nextwordid,textid from chains WHERE wordid = ? ORDER BY random() LIMIT 1", twid #goin' right
      end

      res = res[0]

      if res == nil or res[0] == -1
        break
      end

      if dir <= 0
        sentence >> res[0].to_i
      else
        sentence << res[0].to_i
      end

      if chainlen > 1
        sid = res[1] # Due to the query ordering
        sidi = chainlen-1
      end
    else
      # We know our next word will be from a certain textid, so there should be just one result
      if dir <= 0
        sentence >> ( msg.getFirst( "SELECT wordid FROM chains WHERE nextwordid = ? AND textid = ?", [twid, sid] ).to_i )
      else   
        sentence << ( msg.getFirst( "SELECT nextwordid FROM chains WHERE wordid = ? AND textid = ?", [twid, sid] ).to_i )
      end

      sidi -= 1
      if sidi <= 0
        sid = -1
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
  print "Random speak\n\n"
  if Random.rand > $bot.set.logic.replyrate and msg.message !~ /^#{$bot.nick}[:, ]+/
    return
  end

  # Mash sentences together into one hot mess
  words = []
  msg.sentence.each do |sen|
    words.push( sen.words ).flatten!
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

  # Chain length is random from the config
  chainlen = Random.rand( $bot.set.logic.minchainlength..$bot.set.logic.maxchainlength )
  speak( msg, words[Random.rand(0..(words.size-1))], chainlen ) 
end 
