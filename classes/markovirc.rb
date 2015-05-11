require 'connection_pool'
require 'thread_safe'

# Extend the cinch class to have a exec statement on the database
# that auto executes and autoescapes. This wraps around the previous sqlite3
# gem syntax which I (Billy) have a preference for.

class Markovirc < Cinch::Bot
  attr_accessor :set, :pool, :sentence, :logs
  
  def initialize( )
    @set = Settings.new
    @sentence = nil
    @pool = ConnectionPool.new( size: 10, timeout: 20 ) { PG::Connection.open( :dbname => @set['database'] ) } 
    @logs = ThreadSafe::Hash.new 

    super( )
  end
end
