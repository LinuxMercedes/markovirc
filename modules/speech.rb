require_relative '../classes/sentence.rb'
require 'cinch'

module Speech
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
      $bot.debug "="*40
      $bot.debug "CHAIN RIGHT"
      $bot.debug "="*40 
      # Starts at half so we don't splce the sentence down the middle.
      @chainiterator = chainlen / 2
      new = true
      while self.chain( m, new, :right ) and @words.size < 80
        new = false
        $bot.debug "CHAIN ITERATOR: " + @chainiterator.to_s
        @chainiterator = chainlen and new = !new if @chainiterator <= 0
      end
    end

    """
    Fills our chain out to the left.
    """
    def fillLeft( m, chainlen )
      $bot.debug "="*40
      $bot.debug "CHAIN LEFT"
      $bot.debug "="*40 
      # Starts at half to avoid splicing the sentence down the middle.
      @chainiterator = chainlen / 2
      # False so we use our original source.
      new = false
      while self.chain( m, new, :left ) and @words.size < 80
        new = false
        $bot.debug "CHAIN ITERATOR: " + @chainiterator.to_s
        @chainiterator = chainlen and new = !new if @chainiterator <= 0
      end
    end

    """
    Gets a new word for us and appends it to our words.
    """
    def chain( m, newsource=false, dir )
      nextword = ( dir == :left ? @words.first : @words.last ) 
      field = ( dir == :left ? "nextwid" : "wid" )

      # Get rightmost word's chainid, if we don't have it, get a random one.
      # Always first call of a sentence.
      if newsource 
        $bot.debug "New source"
        #SELECT myid FROM mytable OFFSET random()*N LIMIT 1;
        nextword.textid = m.getFirst_i_rand( "tid", "chains WHERE #{field}=?", nextword.wid ) 

        $bot.debug "\tnextword.textid: " + nextword.textid.to_s
      else
        $bot.debug "Not new source (textid=" + nextword.textid.to_s + ")"
        res = m.getArray( "SELECT #{field} FROM chains WHERE tid=?", nextword.textid ).first
        $bot.debug "\tID and WID query res: " + res.to_s 
        return false if res == nil or res[1] == nil

        nextword = Word.new( self, res[1].to_i, { 'wid' => res[1].to_i, 'textid' => res[0].to_i } )     
        if dir == :left
          @words.unshift nextword
        else
          @words << nextword
        end

        $bot.debug "\tnew textid:" + nextword.textid.to_s
      end

      # Avoid chaining off of punctuation/symbols.
      @chainiterator -= 1 if nextword.text !~ /[,\.!\?\(\)\{\}\-_<>\+=\*\$#@]/

      $bot.debug "\tnew wid: " + nextword.wid.to_s 

      return ( nextword.wid != nil )
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
