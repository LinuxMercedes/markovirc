"""
The Word type is simplifies accessing word ids and getting word test. Before this,
it was necessary to run the same query over and over to get the same values. This 
class should also allow easier implementation of common wid caching in future projects.

member variables:
  @text
    Stores our word text
  @wid
    Stores our word id from our database

functions:
  initialize( word, optional word id )
    Initializes our new word with either wid or text. It can optionally be passed the wid
    for the word which will cause it to not perform a query. If it isn't passed both arguments,
    it preforms a database lookup for the missing one.

  getWid( ) / getWord( )
    Returns the wid of this word or its text respectively. Just accessors.

  to_s( ) / to_i( )
    Returns the text of the word or its word id. These were added with hopes
    of having string concatenation supported without too much fuss.

"""

class Word
  @text = ""
  @wid = nil
  
  attr_accessor :text, :wid
  
  def initialize( msg, word, wid=nil )
    if word.is_a? Integer
      @wid = word
      self.getWord msg
    elsif word.is_a? String and wid == nil
      @text = word
      self.getWid msg
    else
      @text = word
      @wid = wid
    end  
  end

  def length( )
    @text.length
  end

  # Accessors

  def getWid( msg )
    if @wid != nil
      return @wid
    end

    @wid = msg.getFirst "SELECT id FROM words WHERE word=?", @text
    if wid == nil
      msg.getArray "INSERT INTO words (word) VALUES (?)", @text
      @wid = msg.getFirst "SELECT id FROM words WHERE word = ?", @text
    end
  end

  def getWord( msg )
    if @text != ""
      return @text
    end

    @text = msg.getFirst "SELECT word FROM words WHERE id=?", @wid
    if @text == nil
      $bot.error "WID " + @wid.to_s + " was passed to a word constructor but doesn't exist in the database."
    end
  end

  def to_s( )
    @text
  end

  def to_i( )
    @wid
  end
end
