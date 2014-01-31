# FIXME: Give me a constants file
module TYPES
  CHANNEL=0
  PM=1
  DIRECT=2
end

require_relative "utils.rb"

"""
I'm pretty sure sqlite3 handles this natively
First get chanid, then the userid. Check to see if this is a known source, if not
add it, then plug the text in.
"""
def logHandle( db, msg )
  chanid = 0
  userid = 0
  sourceid = 0
  
  res = db.execute "SELECT 1 FROM channels WHERE name=?", msg.channel.name
  if res.size == 0
    db.execute "INSERT INTO channels (name) VALUES (?)", msg.channel.name
  end
  
  chanid = db.get_first_value "SELECT id FROM channels WHERE name=?", msg.channel.name
  
  res = db.execute "SELECT 1 FROM users WHERE hostmask=?", (msg.user.name + "@" + msg.user.host)
  if res.size == 0
    db.execute "INSERT INTO users (hostmask) VALUES (?)", (msg.user.name + "@" + msg.user.host)
  end
  
  userid = db.get_first_value "SELECT id FROM users WHERE hostmask=?", (msg.user.name + "@" + msg.user.host)
  
  res = db.execute "SELECT 1 FROM sources WHERE channelid=? AND userid=?", [chanid, userid]
  if res.size == 0
    db.execute "INSERT INTO sources (channelid,userid,type) VALUES (?,?,?)", [chanid, userid, TYPES::CHANNEL]
  end
  
  sourceid = db.get_first_value "SELECT id FROM sources WHERE userid=? AND channelid=?", [userid, chanid]
  
  db.execute "INSERT INTO text (sourceid, time, text) VALUES (?,?,?)", [sourceid, msg.time.to_i, msg.message]
  
  textid = db.get_first_value "SELECT id FROM text WHERE sourceid=? AND time=? AND text=?", [sourceid, msg.time.to_i, msg.message]
  
  #Create our chain
  chain db, msg.message, textid
end

"""
Chain
Create our chain and throw it into main.chains

We take our base text and split it up into sentences by punctuation.
Next split the sentences by space into a 2d array.
Then replace all words with their word id.
Last create a relation for each word referencing our text.
"""
def chain( db, text, textid )
  sentencewords = sever text
    
  #Replace all words with their ids
  sentencewords.each do |sentence|    
    for i in (0..sentence.size-1)
      word = sentence[i]
      wid = db.get_first_value "SELECT id FROM words WHERE word=?", word
      
      if wid == nil
        db.execute "INSERT INTO words (word) VALUES (?)", word
        wid = db.get_first_value "SELECT id FROM words WHERE word=?", word
      end
      
      sentence[i] = wid
    end
    
    #and insert them
    for i in (0..sentence.size-1)
      if i != sentence.size-1
        db.execute "INSERT INTO chains (wordid,textid,nextwordid) VALUES (?,?,?)", [sentence[i], textid, sentence[i+1]]
      else
        db.execute "INSERT INTO chains (wordid,textid) VALUES (?,?)", [sentence[i], textid]
      end
    end
  end
end

"""
Speak
Pulls a word from our database and starts a chain with it.
"""
def speak( db, msg, word, chainlen, like=false )
  # Number of sentences with our word:
  wid = db.get_first_value "SELECT id FROM words WHERE word" + ( like ? " LIKE ?" : "=?" ) + " COLLATE NOCASE", word
  
  if wid == nil
    msg.reply "I don't know the word: \"#{word}\""
    return
  end
  
  sentencewids = [wid] #our sentence to build
  
  #Go to the left, negative
  speakNext sentencewids, chainlen, -1
  
  #Now to the right, positive
  speakNext sentencewids, chainlen, 1
  
  #Now recursively get the words for each wid
  sentence = []
  sentencewids.each do |wid|
    sentence << ( db.get_first_value "SELECT word FROM words WHERE id=?", wid )
  end
  
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
    q = ""
    
    if twid == -1
      break
    elsif twid == nil
      sentencewids.compact! #dirty fix for sometimes getting nil back in chain len > 1
      break
    end
    
    # If we don't already have a source lined up...
    if sid == -1
      if dir <= 0
        numcontexts = $db.get_first_value "SELECT count(*) FROM chains WHERE nextwordid=?", twid # look for where WE are the next wid
        q = "SELECT wordid,textid from chains WHERE nextwordid=?"
      else
        numcontexts = $db.get_first_value "SELECT count(*) FROM chains WHERE wordid=?", twid # look for our wid
        q = "SELECT nextwordid,textid from chains WHERE wordid=?"
      end
      
      # This typically means our sentence is over.
      if numcontexts == 0
        break
      end
      rownum = Random.rand(0..(numcontexts-1))
      
      $db.execute q, twid do |res|
        if rownum > 0
          rownum -= 1
          next # FIXME: This won't scale well, LIMIT #,# may help
        end
        
        if res[0] == -1
          #Done!
          done = true
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
        
        break
      end
    else
      # We know our next word will be from a certain textid, so there should be just one result
      if dir <= 0
        sentencewids.unshift( $db.get_first_value "SELECT wordid FROM chains WHERE nextwordid=? AND textid=?", [twid, sid] )
      else
        sentencewids << ( $db.get_first_value "SELECT nextwordid FROM chains WHERE wordid=? AND textid=?", [twid, sid] )
      end
      
      sidi -= 1
      if sidi <= 0
        sid = -1
      end
    end
  end
end