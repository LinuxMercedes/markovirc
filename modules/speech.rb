require_relative '../classes/sentence.rb'
require_relative 'penalize.rb'
require 'cinch'

module Speech
  class Chain < Sentence
    include Penalize

    def_delegators :@words, :each, :unshift, :first, :last, :[], :size, :length
    attr_accessor :words, :msg, :chainids
    @newtextid = nil
    @newchainid = nil

    def initialize( msg, words ) 
      super msg, words 
    end
    
    """
    Chain a sentence out in both directions. 
    """
    def fill( m, chainlen, tries=0 )
      # FIXME HACK
      # check for missing chainids
      # Regex only passes a word with a wordid, so it doesn't have a chainid which causes failure
      @words.each do |w|
        if w.chainid == nil 
          w.chainid = m.getFirst_i_rand( "id", "chains WHERE wid=?", [ w.wid ] )
        end
        w.seed = true
      end

      self.fillRight m, chainlen
      self.fillLeft m, chainlen

      return if keep?( m ) or tries > m.bot.set.logic.retries

      # If we're resetting, clear chainid and remove all nonseed entries
      @words.map! { |w| if w.seed then w.chainid = nil; w end }
      @words.compact!
      @chainids = []
      fill m, chainlen, tries+1 # and call again
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
      # If we're going left, we use the first wid in our array in the (below) field
      nextword = ( dir == :left ? @words.first : @words.last ) 
      # If we're going left, we choose the new source/whatever by nextwid
      field = ( dir == :left ? "nextid" : "id" )

      # Get rightmost word's chainid, if we don't have it, get a random one.
      # Always first call of a sentence.
      if newsource 
        $bot.debug "New source"
        res = m.getFirst_array_rand( [ "id", "tid" ], "chains WHERE wid=?", nextword.wid ) 

        if res == nil or res[0] == nil or res[1] == nil
          # chain is done, we're done going this way
          $bot.debug "Couldn't find textid."
          return false
        end

        nextword.chainid = res[0].to_i
        nextword.textid = res[1].to_i

        $bot.debug "\tnextword.textid: " + nextword.textid.to_s

      else

        $bot.debug "Not new source (textid=" + nextword.textid.to_s + ")"

        if dir == :left
          res = m.getArray( "SELECT id,wid FROM chains WHERE nextid=?", nextword.chainid )
        else
          res = m.getArray( "SELECT id,wid FROM chains WHERE id=(SELECT nextid FROM chains WHERE id=?)", 
                  nextword.chainid  )
        end
        $bot.debug "\tID and #{field} query res: " + res.to_s 
        if res == nil or res[0] == nil or res[0][0] == nil or res[0][1] == nil
          # chain is done, we're done going this way
          $bot.debug "Chain terminated\n"
          return false
        end
        res = res.first

        nextword = Word.new( self, res[1].to_i, { 'chainid' => res[0].to_i, 'textid' => nextword.textid } ) 
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
