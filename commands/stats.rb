require 'cinch'
require_relative '../modules/regexparser.rb'

class Stats
  include Cinch::Plugin
  include RegexParser 

  match /stats(.*)/, method: :execute

  def execute( msg, args ) 
    return if not msg.useCommands?

    args = args.strip

    if args == ""
      words = msg.getFirst_i "SELECT MAX(id) FROM words"
      contexts = msg.getFirst_i "SELECT MAX(id) FROM chains"
      texts = msg.getFirst_i "SELECT MAX(id) FROM text"
      channels = msg.getFirst_i "SELECT MAX(id) FROM channels"
      users = msg.getFirst_i "SELECT MAX(id) FROM users"

      msg.reply( "I have #{contexts.commas} chains for #{words.commas} words (~#{(contexts.to_f/words).sigfig 3} ea). "  +
      "I have recorded #{texts.commas} individual messages on #{channels.commas} channels from #{users.commas} users." )
    else
      args = args.split " "

      # Flip between various types of stats searches
      # Regex search for some specific type
      parsed = self.parseRegex args.join " "
      if parsed != nil
        type = parsed[:type]
        mod = parsed[:mod]
        regex = parsed[:regex]
        operator = parsed[:operator]
        c = 0
        name = ""

        $bot.debug "Type: " + type.inspect.to_s + " mod: " + mod.to_s + " operator: " + operator.to_s  \
                   + " regex: " + regex.to_s + "\n\n"

        if type == "u"
          name = "users"
          c = msg.getFirst_i( "SELECT count(id) FROM #{name} WHERE hostmask " + operator + " ?", regex )
        elsif type == "w"
          name = "words"
          c = msg.getFirst_i( "SELECT count(id) FROM #{name} WHERE word " + operator + " ?", regex )
        elsif type == "#"
          name = "channels"
          c = msg.getFirst_i( "SELECT count(id) FROM #{name} WHERE name" + operator + " ?", regex )
        end

        name = "hostmasks" if name == "users"
        msg.reply "There #{( c == 1 ) ? "is" : "are"} #{c} #{c == 1 ? name[0..-2] : name} that" \
                  + " match#{ c == 1 ? "es" : "" } that regex." 

      else
        wid = msg.getFirst "SELECT id FROM words WHERE word = ?", args.join( " " )

        if wid == nil
          msg.reply "I don't know the word \"" + args.join( " " ) + "\""
          return
        end
        # Get the number of times our word occurs before / after any. 
        contextsrhs    = msg.getFirst_i( ( "SELECT COUNT(id) FROM chains WHERE nextid in (SELECT " \
                           + "id FROM chains WHERE wid=?)" ), wid )
        contextslhs    = msg.getFirst_i( ( "SELECT COUNT(id) FROM chains WHERE id in (SELECT nextid " \
                           + "FROM chains WHERE wid=?)" ), wid )

        # Get the word which occurs the most before / after our wid.
        topbefore      = msg.getArray( ("SELECT COUNT(id) AS count, wid FROM chains WHERE nextid in (SELECT " \
                           + "id FROM chains WHERE wid=?) GROUP BY wid ORDER BY count DESC LIMIT 1"), \
                             wid ).first
        topnext        = msg.getArray( ("SELECT COUNT(id) AS count, wid FROM chains WHERE id in (SELECT " \
                           + "nextid FROM chains WHERE wid=?) GROUP BY wid ORDER BY count DESC LIMIT 1"), \
                             wid ).first

        $bot.debug "topnext results: " + topnext.inspect
        $bot.debug "topbefore results: " + topbefore.inspect

        topnexttimes  = topnext.first 
        topbeforetimes= topbefore.first

        topnext       = topnext.last
        topbefore     = topbefore.last

        # Use the overloaded float class to give us x sigfigs.
        if topnexttimes == 0
          topnextfreq = 100.0
        else
          topnextfreq = (topnexttimes.to_f/contextslhs*100).sigfig 4
        end

        if topbeforetimes == 0
          topbeforefreq = 100.0
        else
          topbeforefreq = (topbeforetimes.to_f/contextsrhs*100).sigfig 4 
        end

        # Gracefully handle if this word is commonly at the end of a sentence (nextword == -1) or at the beginning
        # (no nextwordid's point to it) 
        if topnext == nil
          topnext     = ""
        else
          topnext     = msg.getFirst "SELECT word FROM words WHERE id = ?", topnext
        end

        if topbefore == nil 
          topbefore   = ""
        else
          topbefore   = msg.getFirst "SELECT word FROM words WHERE id = ?", topbefore
        end 

        $bot.debug "topbefore word: " + topbefore.to_s
        $bot.debug "topafter word: " + topnext.to_s

        msg.reply "I know " + (contextslhs+contextsrhs).commas + " contexts for \"" + args.join( " " ) + "\""
        msg.reply "The most common preceding word is \"" + topbefore + "\" (" + topbeforefreq.to_s + "%) and the most common " +
          "following word is \"" + topnext.to_s + "\" (" + topnextfreq.to_s + "%)."
      end
    end
  end
end
