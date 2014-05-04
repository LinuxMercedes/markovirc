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

    def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
    attr_accessor :words, :msg

    def initialize( msg, word, chainlen ) 
      @chainlen = chainlen
      @msg = msg

      super msg, word 
    end
    
    # Fill out the left side, working "backwards"
    def chain( )
      res = -1
      if @dir == LEFT 
        res = msg.getFirst_i( "SELECT wordid FROM chains WHERE nextwordid = ? AND textid = ?", [self.first.wid, @srcid] )
      elsif @dir == RIGHT   
        res = msg.getFirst_i( "SELECT nextwordid FROM chains WHERE wordid = ? AND textid = ?", [self.last.wid, @srcid] )
      end

      if res <= 0 or res == nil
        return false
      end

      if @dir == LEFT
        self >> res
      elsif @dir == RIGHT
        self << res
      end

      @chainiter -= 1
      
      true
    end 

    # We need a new source to "emulate" higher chain lengths. A chainlength of 3 means
    # groups of 3 words will always be from a source text and are guaranteed to be as coherent
    # as their source.
    def newsrc( )
      res = ""

      if @dir == LEFT
        @srcid = @msg.getFirst_i "SELECT textid from chains WHERE nextwordid = ? ORDER BY random() LIMIT 1", self.first.wid 
      elsif @dir == RIGHT
        @srcid = @msg.getFirst_i "SELECT textid from chains WHERE wordid = ? ORDER BY random() LIMIT 1", self.last.wid
      end

      if @srcid == nil or @srcid == -1
        @msg.bot.error "EDGE CASE"
        return
      end

      @chainiter = @chainlen # How many more words to pull from this source before a refresh
    end
      
    def fill( )
      # For legacy's sake, let's start by going right.
      @dir = RIGHT

      # Our first word is already in our chain. Now line up a new source before we go further.
      self.newsrc

      1.upto 2 do |i|
        while self.chain and self.length < 25*i 
          if @chainiter == 0
            self.newsrc
          end
        end
        @dir = LEFT
        self.newsrc
      end
    end
  end

  # Make sure our passed word is safe for use, if not then passing it to word will throw it in the database.
  def isSane?( m, word )
    wid = m.getFirst_i "SELECT id FROM words WHERE word ILIKE ? ORDER BY random() LIMIT 1", word

    if wid == nil
      msg.reply "I don't know the word: \"#{word}\""
      false
    else
      true
    end
  end

  # Sanitizes chainlength to fall into specs
  def prepare( m, chainlen )
    xchain = m.bot.set.logic.maxchainlength
    nchain = m.bot.set.logic.minchainlength
    
    # Rope our chain length into whatever config has it set as
    if not chainlen.is_a? Integer or chainlen <= 0
      chainlen = Random.new.rand nchain..xchain
    elsif chainlen > xchain
      chainlen = xchain
    elsif chainlen < nchain
      chainlen = nchain
    end

    return chainlen
  end

  # "Fills" our chain
  def fill( m, word, chainlen )
    res = Chain.new m, chainlen, word
    res.chain
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
