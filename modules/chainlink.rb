require_relative './word.rb'

class ChainLink < Word
  @wid = -1

  @prefix   = ""
  @suffix   = ""

  def initialize( sentence, opt={} )
    super sentence, opt

    @wid      = opt[:wid] if opt.has_key? :wid 

    @prefix   = opt[:prefix] if opt.has_key? :prefix
    @suffix   = opt[:suffix] if opt.has_key? :suffix

    if ( opt.has_key? :get_wid or opt.has_key? :add_wid ) and @wid != nil
      self.getWid( opt )
    elsif ( opt.has_key? :get_word or opt.has_key? :add_word ) and @word != nil
      self.getWord( opt )
    end
  end

  # Accessors
  def getWid( opt={} )
    if @wid != nil
      return @wid
    end

    @wid = @sentence.msg.getFirst "SELECT id FROM words WHERE word=?", @text
    if @wid == nil and opt.has_key? :add_wid
      @sentence.msg.getArray "INSERT INTO words (word) VALUES (?)", @text
      @wid = @sentence.msg.getFirst "SELECT id FROM words WHERE word = ?", @text
    end
    @wid = @wid.to_i
  end

  def getWord( opt={} )
    if @text != nil
      return @text
    end

    @text = @sentence.msg.getFirst "SELECT word FROM words WHERE id = ?", @wid
    if @text == nil or @text.strip == "" )
      print "ERROR: WID '" + @wid.to_s + "' was passed to a ChainLink constructor but doesn't exist in the database.\n"
    end
  end
end
