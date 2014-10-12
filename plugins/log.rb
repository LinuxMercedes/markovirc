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

    #### Store our textid
    # Store our source text for future rehashing / referencing
    @msg.textid = @msg.getFirst "INSERT INTO text (sourceid, time, text) VALUES (?,?,?) RETURNING id", [sourceid, @msg.time.to_i, @msg.message]
  end
end
