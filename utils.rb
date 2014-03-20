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
    sentence << ( $db.get_first_value "SELECT word FROM words WHERE id=?", wid )
  end

  return sentence
end

# Translate our words to wids, expects an array of words to be passed in and returns an array of wids.
def sentenceToWids( sentence )
  sentencewids = []
  sentence.each do |word|
    sentencewids << ( $db.get_first_value "SELECT id FROM words WHERE word=?", word )
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

  def exec( query, args )
    args.each do |arg|
      # Escape and substitute into string. % Is the symbol I'm replacing.
      query.sub! /[^\\]\%/, arg
    end
  end

  # Reads settings from a array of indicies.
  def getSet( keys )
    this = self.set[keys.pop]
    keys.each do |i|
      this = this[i]
    end
  end
end
