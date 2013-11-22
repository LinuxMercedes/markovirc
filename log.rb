#Houses our logging

#FIXME: Maybe add escapes
def logHandle( db, msg )
  chanid = 0
  userid = 0
  sourceid = 0
  
  res = db.execute "SELECT 1 FROM channels WHERE name=\"#{msg.channel.name}\""
  if res.size < 0
    db.execute "INSERT INTO channels (name) (\"#{msg.channel.name}\")"
  end
  chanid = db.get_first_value "SELECT id FROM channels WHERE name=\"#{msg.channel.name}\""
  
  res = db.execute "SELECT 1 FROM users WHERE hostmask=\"#{msg.user.host}\""
  if res.size < 0
    db.execute "INSERT INTO users (hostmask) (\"#{msg.user.host}\")"
  end
  
  userid = db.get_first_value "SELECT 1 FROM users WHERE hostmask=\"#{msg.user.host}\""
  
end