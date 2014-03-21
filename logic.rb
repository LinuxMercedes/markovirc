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

  res = $bot.getArray "SELECT 1 FROM channels WHERE name = ?", msg.channel.name
  if res.size == 0
    $bot.getArray "INSERT INTO channels (name) VALUES (?)", msg.channel.name
  end

  chanid = $bot.getFirst "SELECT id FROM channels WHERE name = ?", msg.channel.name

  res = $bot.getArray "SELECT 1 FROM users WHERE hostmask = ?", (msg.user.name + "@" + msg.user.host)
  if res.size == 0
    $bot.getArray "INSERT INTO users (hostmask) VALUES (?)", (msg.user.name + "@" + msg.user.host)
  end

  userid = $bot.getFirst "SELECT id FROM users WHERE hostmask = ?", (msg.user.name + "@" + msg.user.host)

  res = $bot.getArray "SELECT 1 FROM sources WHERE channelid = ? AND userid = ?", [chanid, userid]
  if res.size == 0
    $bot.getArray "INSERT INTO sources (channelid,userid,type) VALUES (?,?,?)", [chanid, userid, TYPES::CHANNEL]
  end

  sourceid = $bot.getFirst "SELECT id FROM sources WHERE userid = ? AND channelid = ?", [userid, chanid]

  $bot.getArray "INSERT INTO text (sourceid, time, text) VALUES (?,?,?)", [sourceid, msg.time.to_i, msg.message]

  textid = $bot.getFirst "SELECT id FROM text WHERE sourceid = ? AND time = ? AND text=?", [sourceid, msg.time.to_i, msg.message]
  
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
  msg.sentence = Sentence.new msg.message

  # Insert our chains
  sentence.size.times do |i|
    if i != sentence.size-1
      $bot.getArray "INSERT INTO chains (wordid,textid,nextwordid) VALUES (?,?,?)", [sentence[i].getWid, textid, sentence[i+1].getWid]
    else
      $bot.getArray "INSERT INTO chains (wordid,textid) VALUES (?,?)", [sentence[i].getWid, textid]
    end
  end
end

"""
Speak
Pulls a word from our database and starts a chain with it.
"""
def speak( msg, word, chainlen, like=false, widIn=nil )
  if widIn == nil
    # Number of sentences with our word:
    wid = $bot.getFirst "SELECT id FROM words WHERE word" + ( like ? " LIKE ?" : " = ?" ) + " COLLATE NOCASE ORDER BY random() LIMIT 1", word

    if wid == nil
      msg.reply "I don't know the word: \"#{word}\""
      return
    end
  else
    wid = word
  end

  sentencewids = [wid] #our sentence to build

  # Go to the left, negative
  speakNext sentencewids, chainlen, -1

  # Now to the right, positive
  speakNext sentencewids, chainlen, 1

  # Get the words for each wid
  sentence = widsToSentence sentencewids 

  msg.reply sentence.join " "
end

"""
SpeakNext
Helper function for getting the 'next' word. Using dir, it decides which way it is going to
look while iterating through chains. The sentence inputted is an array of wordids
which is added to whilest iterating. 
FIXME: make this a goddamn class
"""
def speakNext( sentencewids, chainlen, dir )
  done = false
  # we use our source id and sourceid counter (sid / sidi) to help us emulate native database support for
  #   higher length markov chains. 
  sid = -1
  sidi = -1

  start = sentencewids.length

  while sentencewids.length < start+25 and not done
    twid = sentencewids[ dir <= 0 ? 0 : -1 ] #thiswid
    res = ""

    if twid == -1
      break
    elsif twid == nil
      sentencewids.compact! #dirty fix for sometimes getting nil back in chain len > 1
      break
    end

    # If we don't already have a source lined up...
    if sid == -1
      if dir <= 0
        res = $bot.getArray "SELECT wordid,textid from chains WHERE nextwordid = ? ORDER BY random() LIMIT 1", twid #goin' left, look to the left
      else
        res = $bot.getArray "SELECT nextwordid,textid from chains WHERE wordid = ? ORDER BY random() LIMIT 1", twid #goin' right
      end

      res = res[0]

      if res == nil or res[0] == -1
        break
      end

      if dir <= 0
        sentencewids.unshift res[0]
      else
        sentencewids << res[0]
      end

      if chainlen > 1
        sid = res[1] # Due to the query ordering
        sidi = chainlen-1
      end
    else
      # We know our next word will be from a certain textid, so there should be just one result
      if dir <= 0
        #print "\nSID: ", sid.to_s, "\nTWID: ", twid.to_s, "\n", sentencewids, "\n\n" 
        sentencewids.unshift( $bot.getFirst "SELECT wordid FROM chains WHERE nextwordid = ? AND textid = ?", [twid, sid] )
      else   
        #print "\nSID: ", sid.to_s, "\nTWID: ", twid.to_s, "\n", sentencewids, "\n\n"
        sentencewids << ( $bot.getFirst "SELECT nextwordid FROM chains WHERE wordid = ? AND textid = ?", [twid, sid] )
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
  else
    print "Activated\n\n"
  end

  bits = sever msg.message

  # Merge sentences so we have one hot mess of words, then translate them to wids.
  sentencewords = bits.flatten

  # Also strip punctuation
  sentencewords.each do |word|
    if word =~ /[\?\!,\.¡̉¿]+$/ 
      word.sub /[\?\!,\.̉¡¿]+$/, ""
    end
    if word =~ /#{$bot.nick}[:,]+/ # (strip out pings)
      sentencewords.delete word
    end
  end

  sentence = sentenceToWids sentencewords

  # Get a corresponding array of the number of chains that mention this wid at any point
  counts = []
  sentence.each do |wid|
    counts << ( $bot.getFirst "SELECT count(*) FROM chains WHERE wordid = ? OR nextwordid = ?", [ wid, wid ] )
  end

  # Drop words with <= one occurence, this means it's brand new and not good fodder.
  i = 0
  counts.each do |num|
    if num <= 1
      counts.delete_at i
      sentence.delete_at i
    else
      i += 1 
    end
  end

  if sentence.length <= 0
    return
  end

  #print "Old sentence \t", sentence, "\n"
  # Sort each word by its appropriate count. This nasty bit sorts words from least occurences to most. 
  sentence = sentence.sort { |x, y| counts[sentence.index( x )] <=> counts[sentence.index( y )] }

  #print "Counts\t\t", counts, "\n"
  #print "New Sentence \t", sentence, "\n\n"

  # Remove the last (most occuring) 55% of the phrase, rounded down so that there's an extra 
  sentence = sentence[0..(sentence.length*0.45).ceil]

  # msg.reply "Candidate words: " + widsToSentence( sentence ).join( ", " )

  # Chain length is random from the config
  chainlen = Random.rand( $bot.set.logic.minchainlength..$bot.set.logic.maxchainlength )
  speak( msg, sentence[Random.rand(0..(sentence.length-1))], chainlen, false, true ) 
end 
