require 'minitest/autorun'

require_relative '../utils.rb'
$set = Settings.new
$set['logic']['minchainlength'] = 4
$set['logic']['maxchainlength'] = 8
require_relative '../commands.rb'

class SayArgParserTest < MiniTest::Unit::TestCase
  def testNormalWord
    input = "word"
    output = sayArgParser(input)
    assert_equal "word", output[0]
  end

  def testWordWithNumericPrefix
    input = "9word"
    output = sayArgParser(input)
    assert_equal "9word", output[0]
  end

  def testWordWithNumericInfix
    input = "wo9rd"
    output = sayArgParser(input)
    assert_equal "wo9rd", output[0]

  end

  def testWordWithNumericPostfix
    input = "word9"
    output = sayArgParser(input)
    assert_equal "word9", output[0]
  end

  def testWordWithNumericPostfixAndLeadingSpace
    input = " word9"
    output = sayArgParser(input)
    assert_equal "word9", output[0]
  end
end
