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
  @text     = nil
  @wid      = nil
  @space    = true 

  @prefix   = ""
  @suffix   = ""

  @sentence = nil
  
  attr_accessor :text, :wid, :prefix, :suffix, :align, :space
  
  def initialize( sentence, opt = { } )
    @sentence = sentence

    @wid      = opt[:wid] if opt.has_key? :wid 
    @text     = opt[:text] if opt.has_key? :text 

    @prefix   = opt[:prefix] if opt.has_key? :prefix
    @suffix   = opt[:suffix] if opt.has_key? :suffix

    @space    = opt[:space] if opt.has_key? :space

    self
  end

  # Accessors
  
  def length( )
    @text.length
  end

#  def getWid( )
#    if @wid != nil
#      return @wid
#    end

#    @wid = @sentence.msg.getFirst "SELECT id FROM words WHERE word=?", @text
#    if wid == nil
#      @sentence.msg.getArray "INSERT INTO words (word) VALUES (?)", @text
#      @wid = @sentence.msg.getFirst "SELECT id FROM words WHERE word = ?", @text
#    end
#    @wid = @wid.to_i
#  end

#  def getWord( )
#    if @text != nil
#      return @text
#    end

#    @text = @sentence.msg.getFirst "SELECT word FROM words WHERE id = ?", @wid
#    if @text == nil or @text.strip == ""
#      print "ERROR: WID " + @wid.to_s + " was passed to a word constructor but doesn't exist in the database."
#    end
#  end

  def to_s( )
    @text
  end

  def to_i( )
    @wid
  end
end
