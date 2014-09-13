require_relative './sentence.rb'

class Chain < Sentence
  @chainiter = -1
  @srcid = -1
  @chainlen = 0
  @msg = nil
  @dir = 0  
  @chainids = nil 
  @thissentence = [ ] 
  @thissentenceids = [ ] 
  @tsiter = -1

  LEFT = -1
  RIGHT = 1

  def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
  attr_accessor :words, :msg, :chainids

  def initialize( word, msg, chainlen=-1 ) 
    @chainlen = chainlen
    @msg = msg
    @chainids = []

    super word 

    self.fill if chainlen != -1
  end

  def word( args=nil )
    args[:add_wid] = true if @chainlen == -1
    ChainLink.new self, args
  end
  
  def chain( )
    if @dir == LEFT
      @tsiter -= 1

      if @tsiter < 0 and @chainiter != 0 
        return false
      end
    elsif @dir == RIGHT
      @tsiter += 1

      if @tsiter >= @thissentence.size and @chainiter != 0 
        return false
      end
    end

    res = @thissentence[@tsiter].to_i
    cid = @thissentenceids[@tsiter].to_i

    if @dir == LEFT
      self >> res
      @chainids.first.unshift cid
      @chainiter += 1 if self.first.text =~ /[\.!:\?,]/
    elsif @dir == RIGHT
      self << res
      @chainids.last.push cid
      @chainiter += 1 if self.last.text =~ /[\.!:\?,]/
    end

    @chainiter -= 1
    true
  end 

  # We need a new source to "emulate" higher chain lengths. A chainlength of 3 means
  # groups of 3 words will always be from a source text and are guaranteed to be as coherent
  # as their source.
  #
  # See below for notes about the changed algorithm. There are two optional parameters for making
  # marko chain off of the last/first words of a chain, instead of off of a single word.
  def newsrc( initial=false, isrcid=-1 )
    res = ""
    twid = -1
    @srcid = nil

    # Catch for initial runs 
    @srcid = isrcid if isrcid != -1

    if @dir == LEFT
      @srcid = @msg.getFirst_i_rand( "textid", "chains WHERE nextwordid = ?", self.first.wid ) if @srcid == nil
      twid = self.first.wid.to_s
      @chainids.unshift []
    elsif @dir == RIGHT
      @srcid = @msg.getFirst_i_rand( "textid", "chains WHERE wordid = ?", self.last.wid ) if @srcid == nil
      twid = self.last.wid.to_s
      @chainids << []
    end

    return false if @srcid <= 0

    # Get the full sentence... can't stream since a specific word we need may not be unique in the sentence
    @thissentence = @msg.getArray( "SELECT wordid FROM chains WHERE textid = ? ORDER BY id ASC", @srcid )
    @thissentenceids = @msg.getArray( "SELECT id FROM chains WHERE textid = ? ORDER BY id ASC", @srcid )
    @thissentence.flatten!
    @thissentenceids.flatten!

    @tsiter = @thissentence.each_index.select{ |i| @thissentence[i] == twid }

    # Now since there can be several matching wids in a sentence, randomly grab one and choose it
    @tsiter = @tsiter.sample if @tsiter.is_a? Array

    # Special catch for the very first run, to put the appropriate chainid in for the word we chained off of 
    if initial and @chainids.size == 1 and @chainids[0].size == 0
      @chainids.first << @thissentenceids[@tsiter] 
    end

    if not initial
      @chainiter = @chainlen # How many more words to pull from this source before a refresh
    else
      @chainiter = (@chainlen/2.0).ceil-1
    end

    @srcid
  end
    
  def fill( )
    # For legacy's sake, let's start by going right.
    @dir = RIGHT

    ###########
    # This part is a change to marko's initial chaining algorithm. 
    # Prior to this, marko would take a word, drop it in a blank chain, 
    # then iterate right off of one source id. It would then iterate backwards
    # starting at that inital word off of ANOTHER sourceid which then led to some
    # spliced text (or rarely, gold).
    # 
    # Our first word is already in our chain. Now line up a new source before we go further.
    initsrc = self.newsrc true
    ##########

    1.upto 2 do |i|
      while self.chain and self.length < 25*i 
        if @chainiter == 0
          next if not self.newsrc
        end
      end
      @dir = LEFT
      next if not self.newsrc true, initsrc
    end
  end
end
