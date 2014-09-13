require "test/unit"

require_relative '../modules/word.rb'
require_relative 'Sever.rb'

class WordTest < Test::Unit::TestCase
  def initialize( test_class )
    @randAll = (32..126).to_a.map! { |w| w.chr }
    @randAlp = (0..9).to_a + ("A".."Z").to_a + ("a".."z").to_a
    @minRandWordSize = 1
    @maxRandWordSize = 100
    super
  end

  def rand_word( type=:all )
    a = ""
    if type == :all
      a = @randAll
    else
      a = @randAlp
    end

    a.shuffle[0, rand(@maxRandWordSize-@minRandWordSize)+@minRandWordSize].join ""
  end

  def test_init_nil
    w = Word.new nil
    
    assert_equal w.text, nil
    
    assert_equal w.to_s, nil 
    assert_equal w.to_i, nil
  end

  def test_init_word
    w = Word.new nil, { text: "Test" }

    assert_equal w.text, "Test" 
    
    assert_equal w.to_s, "Test"    
    assert_equal w.to_i, nil
  end

  def test_capmask_single
    w = Word.new nil, { text: "Word" }

    assert_equal 0b1000, w.cap
  end

  def test_capmask_many
    w = Word.new nil, { text: "wOrDs" }

    assert_equal 0b01010, w.cap
  end

  # Test on a bunch of strings
  def test_capmask_rand_symbols
    (0...100000).to_a.each do
      word = self.rand_word :alph

      w = Word.new nil, { text: word }

      ((w.size-1)..0).to_a.each do |i|
        if word[i] =~ /[[:upper:]]/
          assert( ( w.cap & 2**i ) == 2**i, 
                 "Asserting capital on word '" + w.text + "' on letter '" + word[i] + "'.\n" \
                  + "Calculated value of: '" + ( w.cap & 2**i ).to_s + "' with expected '" + ( 2**i ).to_s + "'\n" \
                  + "Mask of: " + w.cap.to_s + "\n" )
        else
          assert( ( w.cap & 2**i ) == 0, "Asserting not capital on word '" + w.text + "' on letter '" + word[i] + "'.\n" \
                + "Calculated value of: '" + ( w.cap & 2**i ).to_s + "' with expected '0'\n" \
                + "Mask of: " + w.cap.to_s ) 
        end
      end
    end
  end 
end
