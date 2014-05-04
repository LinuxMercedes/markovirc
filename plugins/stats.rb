require 'cinch'

class Stats
  include Cinch::Plugin

  match /stats(.*)/, method: :execute

  def execute( msg, args ) 
    args = args.strip
    if args == ""
      args = "db"
    end

    if args == "db"
      words = msg.getFirst_i "SELECT count(*) FROM words"
      contexts = msg.getFirst_i "SELECT count(*) FROM chains"

      msg.reply "I know " + words.to_s + " words and " + contexts.to_s + " contexts for them, with an average context density of " \
        + (contexts/words).floor.to_s + "."
    else
      args = args.split " "

      if args[0] == "w"
        args.delete_at 0
        wid = msg.getFirst "SELECT id FROM words WHERE word = ?", args.join( " " )
        if wid == nil
          msg.reply "I don't know the word \"" + args.join( " " ) + "\""
          return
        end

        # Get the number of times our word occurs before / after any. 
        contextslhs   = msg.getFirst_i "SELECT count(*) FROM chains WHERE wordid = ?", wid
        contextsrhs   = msg.getFirst_i "SELECT count(*) FROM chains WHERE nextwordid = ?", wid

        # Get the word which occurs the most before / after our wid.
        topnext       = msg.getArray "SELECT nextwordid,count(*) FROM chains WHERE wordid = ? GROUP BY nextwordid ORDER BY count(*) DESC LIMIT 1", wid
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

        msg.reply "I know " + (contextslhs+contextsrhs).to_s + " contexts for " + args.join( " " ) + "."
        msg.reply "The most common preceding word is \"" + topbefore + "\" (" + topbeforefreq.to_s + "%) and the most common " +
          "following word is \"" + topnext.to_s + "\" (" + topnextfreq.to_s + "%)."
      end
    end
  end
end
