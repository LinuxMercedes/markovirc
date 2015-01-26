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
    
    """
    Chain a sentence out in both directions. 
    """
    def fill( m, chainlen )
      self.fillRight m, chainlen
      self.fillLeft m, chainlen
    end

    """
    Fills our chain out to the right. This also grabs and controls our chainlen.
    """
    def fillRight( m, chainlen )
      print "="*40, "\nCHAIN RIGHT\n", "="*40, "\n"
      # Starts at half so we don't splce the sentence down the middle.
      @chainiterator = chainlen / 2
      new = true
      while self.chain( m, new, :right )
        new = !new if new
        print "\nCHAIN ITERATOR: ", @chainiterator, "\n\n"
        @chainiterator = chainlen and new = !new if @chainiterator <= 0
      end
    end

    """
    Fills our chain out to the left.
    """
    def fillLeft( m, chainlen )
      print "="*40, "\nCHAIN LEFT\n", "="*40, "\n"
      # Starts at half to avoid splicing the sentence down the middle.
      @chainiterator = chainlen / 2
      # False so we use our original source.
      new = false
      while self.chain( m, new, :left )
        new = !new if new
        print "\nCHAIN ITERATOR: ", @chainiterator, "\n\n"
        @chainiterator = chainlen and new = !new if @chainiterator <= 0
      end
    end

    """
    Gets a new word for us and appends it to our words.
    """
    def chain( m, newsource=false, dir )
      nextword = ( dir == :left ? @words.first : @words.last ) 
      # New source aggregate wid
      aggwid = ( dir == :left ? "nextwid" : "wid" )
      # Next chain id 
      nextcid = ( dir == :right ? "nextchain" : "id" )
      # Next word id
      nextwid = ( dir == :right ? "nextwid" : "wid" )
      # Our critera for the new parameters
      nextcriteria = ( dir == :left ? "nextchain" : "id" )

      # Get rightmost word's chainid, if we don't have it, get a random one.
      # Always first call of a sentence.
      if newsource 
        print "New source\n"
        res = m.exec( "SELECT id,sum(count) OVER (ORDER BY id) FROM chains WHERE #{aggwid}=? ORDER BY id", [ nextword.wid ] ) 
        print "\tRandom choice res.size: ", res.to_a.size, "\n"
        max = res.to_a.last['sum']  
        print "\tmax value: ", max, "\n"

        # This will be the number below our choice
        choice = rand max.to_i 

        #FIXME: I fear going left will break this vv
        nextword.setChain( res.field_values("sum").bsearch { |i| i.to_i >= choice } )
        print "\tnextword.chainid: ", nextword.chainid, "\n"
      else
        print "Not new source (chainid=", nextword.chainid, ")\n"
        res = m.getArray( "SELECT #{nextcid},#{nextwid} FROM chains WHERE #{nextcriteria}=?", [ nextword.chainid ] ).first
        print "\tID and WID query res: ", res, "\n"
        return false if res == nil or res[1] == nil

        newword = Word.new( self, res[1].to_i, { 'wid' => res[1].to_i, 'chainid' => res[0].to_i } )     
        if dir == :left
          @words.unshift newword
        else
          @words << newword
        end

        print "\tnextword.chainid:", nextword.chainid, "\n"
      end

      @chainiterator -= 1

      print "\tlastword.wid: ", nextword.wid, "\n\n"

      return ( nextword.wid != nil )
    end


    def chainLeft( m, chainiterator, newsource=false )
      firstword = @words.first
      wid = nil

      # Get leftmost word's chainid, if we don't have it, get a random one.
      if newsource 
        print "New source\n"
        res = m.exec( "SELECT id,sum(count) OVER (ORDER BY id) FROM chains WHERE nextwid=? ORDER BY id;", [ firstword.wid ] ) 
        max = res.values.first
        if max.is_a? Array
          max = max.first
        end
        # This will be the number below our choice
        choice = rand(max.to_i)

        firstword.setChain( res.field_values("sum").bsearch { |i| i.to_i >= choice } )
        wid = firstword.wid
        print "\tfirstword.chainid:", firstword.chainid, "\n"
      else
        print "Not new source (chainid=", firstword.chainid, ")\n"

        res = m.getArray( "SELECT id,wid FROM chains WHERE nextchain=?", [ firstword.chainid ] ).first
        print "\tID and WID query res: ", res, "\n"
        return false if res == nil or res[1] == nil

        self.unshift Word.new( self, res[1].to_i, { 'wid' => res[1].to_i, 'chainid' => res[0].to_i } )     

        wid = self.first.wid
        chainid = self.first.wid
        print "\tfirstword.chainid:", firstword.chainid, "\n"
      end

      @chainiterator -= 1

      print "\tfirstword.wid: ", firstword.wid, "\n\n"

      return ( wid != nil and wid != 0 )
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
