#Houses our logging

#FIXME: Give me a constants file
module TYPES
  CHANNEL=0
  PM=1
  DIRECT=2
end

#FIXME: Maybe add escapes, not sure if this is done automatically
#First get chanid, then the userid. Check to see if this is a known source, if not
#  add it, then plug the text in.
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
end