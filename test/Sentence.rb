require "test/unit"

require_relative '../modules/sentence.rb'
require_relative 'Sever.rb'

class SentenceTest < Test::Unit::TestCase
  def initialize( test_class )
    @randAll = (32..126).to_a.map! { |w| w.chr }
    @randAlp = (0..9).to_a + ("A".."Z").to_a + ("a".."z").to_a
    @maxRandWordSize = 10
    @minRandWordSize = 3
    @maxSentenceSize = 100

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

  def rand_array( size=(1+rand(1000)), type=:all )
    if size < 1
      size = 1
    end

    (1..size).to_a.map { self.rand_word type }
  end

  def test_init_nil
    s = Sentence.new

    assert s.is_a? Sentence

    assert_equal s.words, [ ]

    self.assert_sent_equal_array s, [ ] 
  end

  def test_create_from_string
    s = "This is a test sentence." 
    e = %w(This is a test sentence .)

    s = Sentence.new s

    self.assert_sent_equal_array s, e
  end

  def test_create_from_array
    e = %w(This is a test sentence . With a few extra bits tacked on here . This will just keep going on and on .)

    s = Sentence.new e
    
    self.assert_sent_equal_array s, e
  end

  def test_create_from_single_word
    s = "Hello"
    e = %w(Hello)

    s = Sentence.new s

    self.assert_sent_equal_array s, e 
  end

  def test_append
    s = "This is a test sentence." 
    e = %w(This is a test sentence . With a few extra bits tacked on here . This will just keep going on and on .)
    
    s = Sentence.new s 
    a = e.drop s.size

    # Test 
    i = s.size
    a.map { |w| s << w; i += 1; assert_equal s.size, i, ( "Failed to assert equality at " + i.to_s ) }

    self.assert_sent_equal_array s, e
  end

  def test_prepend
    s = "This will just keep going on and on." 
    e = %w(This is a test sentence . With a few extra bits tacked on here . This will just keep going on and on .)
    
    s = Sentence.new s 
    a = e[0...e.size-s.size].reverse

    # Test
    i = s.size
    a.map { |w| s >> w; i += 1; assert_equal s.size, i, ( "Failed to assert equality at " + i.to_s ) }

    self.assert_sent_equal_array s, e
  end

  def test_rand_create_from_string_with_symbols
    (1..@maxSentenceSize).to_a.each do |i|
      sent = self.rand_array i
      s_string = Sentence.new sent.join " "

      assert( s_string.size >= sent.size, ( "Failed to assert >= at " + i.to_s + " with other size " + s_string.size.to_s ) )
    end 
  end

  def test_rand_create_from_array_with_symbols
    (1..@maxSentenceSize).to_a.each do |i|
      sent = self.rand_array i
      s_array = Sentence.new sent

      assert( s_array.size >= sent.size, ( "Failed to assert >= at " + i.to_s + " with other size " + s_array.size.to_s ) )
      # Eventually assert that == ^
    end
  end

  def test_rand_create_from_string_alphanumeric
    (1..(@maxSentenceSize)).to_a.each do |i|
      sent = self.rand_array i, :alpha
      s_string = Sentence.new sent.join " "

      assert_equal( s_string.size, sent.size, ( "Failed to assert equality at " + i.to_s + " with other size " + s_string.size.to_s ) )
    end
  end

  def test_rand_create_from_array_alphanumeric
    (1..(@maxSentenceSize)).to_a.each do |i|
      sent = self.rand_array i, :alpha
      s_array = Sentence.new sent

      assert_equal( s_array.size, sent.size, ( "Failed to assert equality at " + i.to_s + " with other size " + s_array.size.to_s ) )
    end
  end
  
  def assert_sent_equal_array( sentence, array )
    # Check that the array's sizes are equal
    assert_equal array.size, sentence.size

    # Check that the two arrays are equal
    for i in array.size.times do
      assert_equal array[i], sentence[i].to_s
    end
  end
end
