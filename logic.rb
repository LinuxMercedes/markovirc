#Houses our logic / reading of stuff

#FIXME: Give me a constants file
module TYPES
  CHANNEL=0
  PM=1
  DIRECT=2
end

"""
NO ESCAPES. I'm pretty sure sqlite3 handles this natively
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
Create our chain and throw it into main.chains
  We take our base text and split it up into sentences by punctuation.
  Next split the sentences by space into a 2d array.
  Then replace all words with their word id.
  Last create a relation for each word referencing our text.
"""
def chain( db, text, textid )
  sentences = text.split( /[.!?]+/ )
  sentencewords = []
  
  sentences.each do |sentence|
    sentencewords << sentence.split( /[\s]+/ ).delete_if { |a| a == "" }
  end
  
  #Replace all words with their ids
  sentencewords.each do |sentence|
    print sentence
    print "\n"
    
    for i in (0..sentence.size-1)
      word = sentence[i]
      wid = db.get_first_value "SELECT id FROM words WHERE word=?", word
      
      if wid == nil
        db.execute "INSERT INTO words (word) VALUES (?)", word
        wid = db.get_first_value "SELECT id FROM words WHERE word=?", word
      end
      
      sentence[i] = wid
    end
    
    print sentence
    print "\n"
    
    for i in (0..sentence.size-1)
      if i != sentence.size-1
        db.execute "INSERT INTO chains (wordid,textid,nextwordid) VALUES (?,?,?)", [sentence[i], textid, sentence[i+1]]
      else
        db.execute "INSERT INTO chains (wordid,textid) VALUES (?,?)", [sentence[i], textid]
      end
    end
  end
  
  print "\n"
end