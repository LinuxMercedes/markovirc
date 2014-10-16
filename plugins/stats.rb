require 'cinch'

class Stats
  include Cinch::Plugin

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

      msg.reply( "I have #{contexts.commas} contexts for #{words.commas} (~#{(contexts.to_f/words).sigfig 3} ea) for them. " +
       "I have recorded #{texts.commas} individual messages on #{channels.commas} channels from #{users.commas} users." )
      
      
      
    else
      args = args.split " "

      # Flip between various types of stats searches
      # Regex search for some specific type
      if args[0] =~ /^(?<type>[u#w])?\/(?<regex>[^\/]*)\/(?<mod>[i!]+)?$/
        m = Regexp.last_match
        type = m[:type]
        mod = m[:mod]
        regex = m[:regex]
        type = "w" if type == "" or type == nil
        mod = "" if mod == nil
        mod = mod.split ""
        c = 0
        name = ""
        operator = ( mod.include?('!') ? '!' : '' ) + "~" + ( mod.include?('i') ? '*' : '' ) 

        print "Type: ", type.inspect, " mod: ", mod, " operator: ", operator, " regex: ", regex, "\n\n"

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
        msg.reply "There #{( c == 1 ) ? "is" : "are"} #{c} #{c == 1 ? name[0..-2] : name} that match#{ c == 1 ? "es" : "" } that regex." 

      elsif args[0] =~ /^\#[^\s]+$/
        channelid = msg.getFirst_i "SELECT id FROM channels WHERE name = ?", args[0] 

        if channelid != nil and channelid > 0
          contexts = msg.getFirst_i "SELECT count(*) FROM chains
                                     LEFT JOIN text ON (text.id = chains.textid)
                                     LEFT JOIN sources ON (text.sourceid = sources.id)
                                     WHERE channelid = ?", channelid 
          msg.reply "I have " + contexts.commas + " contexts for " + args[0] + "." 
        else
          msg.reply "I have no contexts for " + args[0] + "."
        end
      else
        wid = msg.getFirst "SELECT id FROM words WHERE word = ?", args.join( " " )

        if wid == nil
          msg.reply "I don't know the word \"" + args.join( " " ) + "\""
          return
        end
        # Get the number of times our word occurs before / after any. 
        contextslhs   = msg.getFirst_i "SELECT count(*) FROM chains WHERE wordid = ? and nextwordid != ?", [ wid, "-1" ]
        contextsrhs   = msg.getFirst_i "SELECT count(*) FROM chains WHERE nextwordid = ?", wid

        # Get the word which occurs the most before / after our wid.
        topnext       = msg.getArray "SELECT nextwordid,count(*) FROM chains WHERE wordid = ? AND nextwordid != ? GROUP BY nextwordid ORDER BY count(*) DESC LIMIT 1", [ wid, "-1" ]
        topbefore     = msg.getArray "SELECT wordid,count(*) FROM chains WHERE nextwordid = ? GROUP BY wordid ORDER BY count(*) DESC LIMIT 1", wid

        # The query above returns a double array in the format [[topwid, somecount]]
        topnext       = topnext[0][0].to_i
        topbefore     = topbefore[0][0].to_i

        topnexttimes  = msg.getFirst_i "SELECT count(*) FROM chains WHERE wordid = ? AND nextwordid = ?", [ wid, topnext ]
        topbeforetimes  = msg.getFirst_i "SELECT count(*) FROM chains WHERE wordid = ? AND nextwordid = ?", [ topbefore, wid ]

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
        if topnext == nil or topnext == "-1" or topnext == -1
          topnext     = ""
        else
          topnext     = msg.getFirst "SELECT word FROM words WHERE id = ?", topnext
        end

        if topbefore == nil or topbefore == -1
          topbefore   = ""
        else
          topbefore   = msg.getFirst "SELECT word FROM words WHERE id = ?", topbefore
        end 

        msg.reply "I know " + (contextslhs+contextsrhs).commas + " contexts for \"" + args.join( " " ) + "\""
        msg.reply "The most common preceding word is \"" + topbefore + "\" (" + topbeforefreq.to_s + "%) and the most common " +
          "following word is \"" + topnext.to_s + "\" (" + topnextfreq.to_s + "%)."
      end
    end
  end
end
