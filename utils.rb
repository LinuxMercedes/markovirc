require 'settingslogic'
require 'connection_pool'
require 'thread_safe'

require_relative 'modules/sever.rb'

class Settings < Settingslogic
  if ARGV[0] == nil
    source "config.yml"
  else
    source ARGV[0]
  end
end

# Overload float with an option for significant figure rounding.
class Float
  def sigfig(signs)
    Float("%.#{signs}g" % self)
  end
end

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

module DatabaseTools
  attr_accessor :sentence, :textid, :sourceid, :db

  @pool = @sentence = @textid = @sourceid = @db = nil

  def getFirst( query, args=[] )
    res = self.exec( query, args ).values.first

    if res.is_a? Array
      res = res[0]
    end
  end

  #By default the type of everything returned is a string. 
  def getFirst_i( query, args=[] )
    res = self.exec( query, args ).values.first

    if res.is_a? Array
      res = res[0]
    end
    
    #self.bot.debug query + " args: " + args.inspect + "\n"

    res.to_i
  end

  # Wraps around getFirst_i to return a random int
  def getFirst_i_rand( selection, query, args )
    # Double our args since we are querying twice
    
    args = [ args ] if not args.is_a? Array

    nargs = Array.new args
    args.each do |a|
      nargs << a 
    end

    args = nargs
    
    return( self.getFirst_i( "SELECT " + selection + " FROM " + query + " OFFSET floor(RANDOM() * (SELECT count(*) FROM " + query + ")) LIMIT 1", args ) )
  end 

  # Wraps around getFirst_i to return a random int
  def getFirst_array_rand( selection, query, args )
    # Double our args since we are querying twice
    
    args = [ args ] if not args.is_a? Array

    nargs = Array.new args
    args.each do |a|
      nargs << a 
    end

    args = nargs
    
    r = self.getArray( "SELECT " + selection + " FROM " + query + " OFFSET floor(RANDOM() * (SELECT count(*) FROM " + query + ")) LIMIT 1", args ) 
    
    r = r[0] if r.is_a? Array and r.size == 1

    r
  end 

  def getArray( query, args )
    self.exec( query, args ).values
  end

  def exec( query, argsin )
    args = Array.new

    if not argsin.is_a? Array
      args = [ argsin ]
    else
      args = argsin
    end


    # Escape args which contain ?
    args.map! { |a| a.to_s.gsub( /\?/, '\\?' ) }

    # Replace our ?'s with our args in order. Escape them and use exec
    # for compatibility with jruby_pg and pg.
    args.each do |arg|
      query.sub! /(?<!\\)\?/ do
        if @pool != nil
          @pool.with do |conn|
            "'" + conn.escape_string( arg ) + "'"
          end
        else
          "'" + $conn.escape_string( arg ) + "'"
        end
      end
    end

    # Now go back and change any escaped ?s to regular ?s (we escape already escaped ?s twice)
    query.gsub! /\\\?/, '?'
    
    # Check whether we're using a pool or a global connection
    if @pool != nil
      @pool.with do |conn| 
        conn.exec_params query
      end
    else
      $conn.exec_params query, args
    end
  end
end

# Message is overloaded to serve as a database query handler.
class Cinch::Message
  include DatabaseTools
  alias_method :old_initialize, :initialize
  attr_accessor :pool

  def initialize( msg, bot )
    @pool = bot.pool

    old_initialize msg, bot
  end

  def useCommands?( )
    channel = $bot.set['channels'][self.channel]
    
    if channel.length == 0
      return true
    end

    if channel.include? 'silent' or channel.include? '-commands'
      false
    else
      true
    end
  end

  def canSpeak?( )
    channel = $bot.set['channels'][self.channel]

    if channel.include? 'silent' or channel.include? '-speak'
      false
    else
      true
    end
  end

  def canRespond?( )
    channel = $bot.set['channels'][self.channel]
    
    if ( channel.include? 'hilight' or ( not channel.include? 'silent' and not channel.include? '-speak' ) ) and self.message =~ /^#{$bot.nick}[:, ]+/  
      true
    else
      false
    end
  end
end

def reqdir( dir )
  Dir.entries( dir ).each do |fn|
    if fn == '.' or fn == '..'
      next
    end

    if File.directory? fn
      next
    elsif File.fnmatch '*.rb', fn
      load File.dirname( __FILE__ ) + "/" + dir + fn
    end
  end
end

# Formatting for commas
class Fixnum
  def commas( )
    s = self.to_s.reverse 

    # Follow, backwards, all groups of 3 numbers with a comma
    s.gsub( /([0-9]{3})/, "\\1," ).gsub( /,$/, "" ).reverse
  end
end

# Return a hash where a word => wid
def widHash( txt, conn )
  # Go through each wid and make sure we've got it
  words = conn.exec("SELECT id,word FROM words WHERE word in ('" + txt.uniq.map{ |w| conn.escape_string w }.join("','") + "')").values
  idhash = Hash.new

  words.each do |w|
    idhash[w[1]] = w[0]
  end


  idhash
end
