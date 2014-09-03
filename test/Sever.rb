
require 'cinch'
require "test/unit"

require_relative '../utils.rb'
require_relative '../modules/sentence.rb'

class SentenceTest < Test::Unit::TestCase
  def test_unicode
    s = "David Cameron: Taxes will rise unless we can raid bank accounts ( ﾟ∀ﾟ)ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼"
    e = %w(David Cameron : Taxes will rise unless we can raid bank accounts ( ﾟ∀ﾟ)ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼)

    self.assert_sentence s, e
  end

  def test_latex
    s = "4Artist: 12 m3n Soundtrack 3:: YouTube Shinedown - I'm advancing... Doing (g^{y_i})^{x_i} I don't actually know who sits in front of draenor."
    e = %w(4Artist : 12 m3n Soundtrack 3 :: YouTube Shinedown - I ' m advancing ... Doing ( g ^{ y _ i })^{ x _ i } I don ' t actually know who sits in front of draenor .)
    
    self.assert_sentence s, e
  end

  def test_url
    s = "http://youtu.be/55byw2NSuPI A Skylit Drive - Love the Way You Lie - 00:04:58 - 236723 views"
    e = %w(http://youtu.be/55byw2NSuPI A Skylit Drive - Love the Way You Lie - 00 : 04 : 58 - 236723 views)

    self.assert_sentence s, e
  end

  def test_temp
    s = "huh I'd still want you to be taught and read up on Eight Floppy Drives | Lo: 53.53°F"
    e = %w(huh I ' d still want you to be taught and read up on Eight Floppy Drives | Lo : 53 . 53 ° F)

    self.assert_sentence s, e
  end

  def assert_sentence( base_sentence, array )
    print "\n\n"
    # Run sentence in, through, and back out
    sentence = Sentence.new base_sentence  

    print "Sentence in: ", base_sentence, "\n"
    print "Sentence out: ", sentence.to_s, "\n\n"

    # Check that the array's sizes are equal
    assert_equal array.size, sentence.size

    # Check that the two arrays are equal
    for i in array.size.times do
      assert_equal array[i], sentence[i].to_s
    end

    # Check that the output is equal to our input
    assert_equal base_sentence, sentence.to_s 
  end
end
