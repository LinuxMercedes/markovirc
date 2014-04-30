require 'settingslogic'

# Intelligently split a sentence by punctuation, then split the individual spaces
# so we get words.
def sever( text )
  sentences = text.split( /[.!?][ ]+/ )
  sentencewords = []
  
  sentences.each do |sentence|
    sentencewords << sentence.split( /[\s]+/ ).delete_if { |a| a == "" }
  end
  
  return sentencewords
end

class Settings < Settingslogic
    source "config.yml"
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
  attr_accessor :set
  
  def initialize( )
    @set = Settings.new
    super( )
  end
end

# Add a textid and sentence field to the message

class Cinch::Message
  attr_accessor :sentence, :textid, :sourceid, :db

  @db = @sentence = @textid = @sourceid = nil
 
  # Connect to our database. A message travels through an entire thread, so this is a personal connection. 
  # FIXME: Add disconnect when deconstructed.
  def connect( )
    @db  = PG::Connection.open( :dbname => $bot.set['database'] ) 
  end

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
    
    @db.exec_params query, args
  end

  def useCommands?( )
    channel = $bot.set['channels'][self.channel]

    if channel.include? 'silent' or channel.include? '-commands'
      false
    else
      true
    end
  end

  def canSpeak?( )
    channel = $bot.set['channels'][self.channel]

    if channel.include? 'silent' and not channel.include? 'hilight'
      false
    elsif channel.include? '-speak' and not channel.include? 'hilight'
      false
    else
      true
    end
  end

  def canRespond?( )
    channel = $bot.set['channels'][self.channel]
    
    if channel.include? 'hilight'
      true
    else
      false
    end
  end
end
