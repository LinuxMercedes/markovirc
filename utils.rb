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

# Translate our wids to words, expects an array of wids and returns an array of words
def widsToSentence( sentencewids )
  sentence = []
  sentencewids.each do |wid|
    sentence << ( $bot.getFirst "SELECT word FROM words WHERE id = ?", wid )
  end

  return sentence
end

# Translate our words to wids, expects an array of words to be passed in and returns an array of wids.
def sentenceToWids( sentence )
  sentencewids = []
  sentence.each do |word|
    sentencewids << ( $bot.getFirst "SELECT id FROM words WHERE word = ?", word )    
  end

  return sentencewids
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
  attr_accessor :set, :db
  
  def initialize( )
    @set = Settings.new
    @db  = PG::Connection.open( :dbname => @set['database'] ) 
    super( )
  end

  def getFirst( query, args )
    res = self.exec( query, args ).values.first

    if res.length == 1
      res = res[0]
    end
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
    
    print "\n\n\n", query, "\n", args, "\n\n\n" 
    @db.exec_params query, args
  end
end

# Add a textid and sentence field to the message

class Cinch::Message
  attr_accessor :sentence, :textid, :sourceid

  @sentence, @textid, @sourceid = nil
end
