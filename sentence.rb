require 'forwardable'

"""
The long awaited sentence class. This class allows easy manipulation of sentences
without having to fumble with arrays and unshift all the time. This makes life
so very much easier and the code look much cleaner in the end.

Member variables:
  @words
    This variable houses our sentence in an array. Each member is a Word (class)
    and contains their own wids / text.    
  WORDS / WIDS
    These are constants used only internally. They assist in determining the
    argument passed to the initialize function to hand off to another function.

Functions:
  initialize( Array words )
    Initialize is called on object creation and is passed an array of Integers,
    a String, an Array of Strings, or an array of Words. If a string is passed
    it intelligently splits and grabs the first array of strings handles it
    like it was passed that. 

    If passed an array of strings or wids, it converts them to Words and stores
    them in @words. If passed nil, it just leaves as is with a blank array.

  <<( word ):
    This function simply pops a word onto the rightmost space of the sentence. It 
    blindly converts the argument into a word if it isn't one already.

  >>( word ):
    This function simply pops a word onto the leftmost space of the sentence. It
    blindly converts the argument into a word if it isn't one already.

  Inheritied array functions: each, [], unshift, first, last
"""
class Sentence 
  include Enumerable
  extend Forwardable

  @sid = -1
  @channel = -1

  def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
  attr_accessor :words, :msg

  def initialize( msg, words=nil )
    wordsarray = []
    @words = []
    @msg = msg

    #FIXME: these first three options may be borked
    if words.is_a? String
      wordsarray = sever( words ).first  
    elsif words.is_a? Array and words.length > 0 and words[0].is_a? Word
      @words = words
      return
    elsif words.is_a? Array
      wordsarray = words
    elsif words.is_a? Cinch::Message
      wordsarray = sever( words.message ).first # always returns at least an array with one sentence
    elsif words.is_a? Word
      @words << words
      return
    else
      return # Hopefully nil
    end
    
    wordsarray.each do |word|
      @words << ( Word.new self, word )
    end
  end

  # Drop a new word on the end of our sentence
  def <<( word )
    if not word.is_a? Word
      word = Word.new self, word
    end

    words << word
  end

  def >>( word )
    if not word.is_a? Word
      word = Word.new self, word
    end

    words.unshift word
  end

  def join( joiner )
    words = []
    @words.each do |word|
      words << word.text
    end

    words.join joiner
  end
end
