require_relative '../modules/sentence.rb'

module Speech
  LEFT = -1
  RIGHT = 1

  class Chain < Sentence
    def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
    attr_accessor :words, :msg, :chainids

    def initialize( msg, words ) 
      super msg, words 
    end
    
    def chain( )

    end 
      
    """
    Chain a sentence out in both directions. 
    """
    def fill( m, chainlen )
      self.fillLeft m, chainlen
      self.fillRight m, chainlen
    end

    """
    Fills our chain out to the right. This also grabs and controls our chainlen.
    """
    def fillRight( m, chainlen )
      @chainiterator = chainlen
      new = true
      while self.chainRight( m, new )
        new = !new if new
        print "\nCHAIN ITERATOR: ", @chainiterator, "\n\n"
        @chainiterator = chainlen and new = !new if @chainiterator <= 0
      end
    end

    """
    Fills our chain out to the left.
    """
    def fillLeft( m, chainlen )
    end

    """
    Gets a new word for us and appends it to our words.
    """
    def chainRight( m, newsource=false )
      lastword = @words.last
      wid = nil

      # Get rightmost word's chainid, if we don't have it, get a random one.
      # Always first call of a sentence.
      if newsource 
        print "New source\n"
        res = m.exec( "SELECT id,sum(count) OVER (ORDER BY id) FROM chains WHERE wid=? ORDER BY id;", [ lastword.wid ] ) 
        max = res.values.last
        if max.is_a? Array
          max = max.last
        end
        # This will be the number below our choice
        choice = rand(max.to_i)

        lastword.setChain( res.field_values("sum").bsearch { |i| i.to_i >= choice } )
        wid = lastword.wid
        print "\tlastword.chainid:", lastword.chainid, "\n"
      else
        print "Not new source (chainid=", lastword.chainid, ")\n"
        nextid = m.getFirst_i( "SELECT nextchain FROM chains WHERE id=?", lastword.chainid )
        print "\tNextid: ", nextid, "\n"

        res = m.getArray( "SELECT id,wid FROM chains WHERE id=?", [ nextid ] ).first
        print "\tID and WID query res: ", res, "\n"
        return false if res == nil

        self << Word.new( self, res[1].to_i, { 'wid' => res[1].to_i, 'chainid' => res[0].to_i } )     

        wid = self.last.wid
        chainid = self.last.wid
        print "\tlastword.chainid:", lastword.chainid, "\n"
      end

      @chainiterator -= 1

      print "\tlastword.wid: ", lastword.wid, "\n\n"

      return ( wid != nil and wid != 0 )
    end


    def chainLeft( m, chainiterator, newsource=false )
      return false
    end
  end

  """
  Wrapper for some common say functions. Grabs the last argument,
  if it's numeric, and returns it as level.
  """
  def sayArgParser( args )
    args = args.strip
    word = args
    type = ""
    operator = ""

    # Args can take several forms, usually something like this
    # !say /match/ #
    # !say word #
    # !say word or !say match
    # !say wo%d
   
    /^(?<word>.+)(?<level>\s[0-9]+)?$/ =~ args
    level.strip! if level != nil

    regexinfo = self.parseRegex word
    if regexinfo != nil
      type = "regex"
    else
      type = "word"
    end
    
    return word, level, type, regexinfo
  end
end
