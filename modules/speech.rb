require_relative '../modules/sentence.rb'

module Speech
  LEFT = -1
  RIGHT = 1

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

    def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
    attr_accessor :words, :msg, :chainids

    def initialize( msg, word, chainlen ) 
      @chainlen = chainlen
      @msg = msg
      @chainids = []

      super msg, word 

      self.fill
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

      if @dir == LEFT
        @srcid = @msg.getFirst_i_rand "textid", "chains WHERE nextwordid = ?", self.first.wid 
        twid = self.first.wid.to_s
        @chainids.unshift []
      elsif @dir == RIGHT
        @srcid = @msg.getFirst_i_rand "textid", "chains WHERE wordid = ?", self.last.wid
        twid = self.last.wid.to_s
        @chainids << []
      end

      # Get the full sentence... can't stream since a specific word we need may not be unique in the sentence
      @thissentence = @msg.getArray( "SELECT wordid FROM chains WHERE textid = ?", @srcid )
      @thissentenceids = @msg.getArray( "SELECT id FROM chains WHERE textid = ?", @srcid )
      @thissentence.flatten!
      @thissentenceids.flatten!

      @tsiter = @thissentence.each_index.select{ |i| @thissentence[i] == twid }.sample

      # Now since there can be several matching wids in a sentence, randomly grab one and choose it

      if not initial
        @chainiter = @chainlen # How many more words to pull from this source before a refresh
      else
        @chainiter = (@chainlen/2.0).ceil-1
        if isrcid != -1
          @srcid = isrcid
        end
        @srcid
      end
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
            self.newsrc
          end
        end
        @dir = LEFT
        self.newsrc true, initsrc
      end
    end
  end

  """
  Wrapper for some common say functions. Grabs the last argument,
  if it's numeric, and returns it as level.
  """
  def sayArgParser( args )
    args.strip!
    word = args
    level = nil
   
    #Do a bit of black magic to separate a number argument at the end of a !say command from 
    # the requested word
    if args.match /[ ]+/
      args = args.split /[ ]+/
      args.delete ""
      if args[-1] =~ /[0-9]{1,2}/
        word = args[0...-1].join " "
        level = args[-1].to_i
      end
    end
    
    return word, level
  end
end
