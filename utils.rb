require 'settingslogic'
require 'connection_pool'

# Intelligently split a sentence by punctuation, then split the individual spaces
# so we get words.
def sever( text )
  sentences = text.scan /([^\.!":?,]+)([\.!"?:,]+)/ 
  sentences.flatten!

  last = 0 
  while last != sentences.length
    last = sentences.length

    # Inspect for smashed urls
    sentences.length.times do |i|
      if sentences[i] =~ /^[\.!?:]+$/ and sentences.length > i+1 and sentences[i+1][0] !~ /[\s]/
        sentences[i-1] = sentences[(i-1)..(i+1)].join ''
        sentences.delete_at i
        sentences.delete_at i
        break 
      end
    end
  end

  sentences.map! { |x| x.split /\s+/ }
  sentences.flatten!
  sentences.delete_if { |x| x == "" }

  return sentences
end

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
  attr_accessor :set, :pool
  
  def initialize( )
    @set = Settings.new
    @pool = ConnectionPool.new( size: 10, timeout: 20 ) { PG::Connection.open( :dbname => @set['database'] ) } 
    super( )
  end
end

# Message is overloaded to serve as a database query handler.
class Cinch::Message
  attr_accessor :sentence, :textid, :sourceid, :db

  @sentence = @textid = @sourceid = @db = nil

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
    
    self.bot.debug query + " args: " + args.inspect + "\n"

    res.to_i
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

    args.length.times do |i|
      query.sub! /(?!\\)\?/, "$#{i+1}" # Postgres friendly format
    end
    
    self.bot.pool.with do |conn| 
      conn.exec_params query, args
    end
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
