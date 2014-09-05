require 'forwardable'
require 'uri'
require 'strscan'
require_relative 'word.rb'

"""
This class allows easy manipulation of sentences
without having to fumble with arrays and unshift all the time. This makes life
so very much easier and the code look much cleaner in the end.
"""
class Sentence 
  include Enumerable
  extend Forwardable

  def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
  attr_accessor :words

  def initialize( words=nil )
    @words = [ ]

    wordsarray = []

    if words.is_a? String
      self.sever words
      return self
    elsif words.is_a? Array
      wordsarray = words
    else
      return self
    end

    wordsarray.each do |word|
      @words << prepare_word( word ) 
    end
  end

  # Drop a new word on the end of our sentence
  def <<( word )
    words << self.prepare_word( word )
  end

  def >>( word )
    words.unshift self.prepare_word( word )
  end

  def prepare_word( word )
    if not word.is_a? Word
      if word.is_a? String
        word = Word.new self, { :text => word }
      elsif word.is_a? Integer
        word = Word.new self, { :wid => word }
      end
    end

    word
  end

  def sever( sent )
    # Scan the sentence, breaking up by space:
    s = StringScanner.new sent
    w = ""
    debug = false

    while not s.eos?
      w = s.scan /[^\s]+/
      print( "Matching: '#{w}' ('", s.matched, "')\n" ) if debug

      if w == nil
        w = s.skip /[\s]+/
        print( "Skipping: #{w} ('", s.matched, "')\n" ) if debug
        next
      end

      # Check if is URL, which we ignore.
      if ( w =~ /([A-Za-z]{2,15}:)?[^\.]+\.[^\.]+.+/ and w =~ URI::regexp ) or w =~ /[\w\._\-!]+\@[\w\._\-!]+/
        space = ( @words.size != 0 )
        @words << Word.new( self, { :text => w, :space => space } )
        print( "Is URL #{w} ('", s.matched, "')\n" ) if debug
        next
      end

      print( "w is: \"", w, "\"\n" ) if debug
      first = true

      # Scan further for punctuation
      s2 = StringScanner.new w
      while not s2.eos?
        space = false
        sep   = "[:alpha:]0-9"
        sepp  = "[#{sep}]"
        sepn  = "[^#{sep}]"

        w2 = s2.scan /#{sepn}+/
        w2 = s2.scan( /#{sepp}+/ ) if w2 == nil

        print( "  w2 is: \"", w2, "\"\n" ) if debug

        if first and @words.size != 0
          print( "    Space\n" ) if debug
          space = true
          first = false
        elsif @words.size == 0
          first = false
        end

        @words << Word.new( self, { :text => w2, :space => space } )
      end
    end
  end

  def to_s
    @words.map{ |w| w.to_s( true ) }.join ""
  end

  def +( rhs )
    self.to_s + rhs.to_s
  end
end
