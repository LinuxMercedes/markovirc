#Master file for commands

#Need to essentially prototype this or help won't compile
$commands = { }

"""
Help looks up a commands information in the command hash.
  Using $commands.each it iterates through all command's keys and sends out
  information about each, using the short description. If an argument follows
  it prints information about that command, otherwise it complains.
"""
def help( args, msg )
  args = args.strip
  
  if args == ""
    msg.channel.send "Commands available: "
    $commands.each do |cmd, info|
      msg.channel.send "  " + cmd + ": " + info[1]
    end
  elsif $commands.key?(args)
    $commands[args][2].each do |txt|
      msg.channel.send txt
    end
  else
    msg.reply "Unknown command: \"" + args + "\""
  end
end

#force it to speak
def say( args, msg )
  word, level = sayArgParser( args )

  wid = msg.getFirst "SELECT id FROM words WHERE word ILIKE ? ORDER BY random() LIMIT 1", word

  if wid == nil
    msg.reply "I don't know the word: \"#{word}\""
    return
  end

  speak msg, word, level
end

def sayl( args, msg )
  word, level = sayArgParser( args )
  
  if not word =~ /\%/
    iword = "%#{word}%"
  else
    iword = word
  end

  wid = msg.getFirst "SELECT id FROM words WHERE word ILIKE ? ORDER BY random() LIMIT 1", iword

  if wid == nil
    msg.reply "I don't know any words containing: \"#{word}\""
    return
  end

  speak msg, word, level
end

#Statistics
def stats( args, msg )
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

def shutup( args, msg )
  
end

def speak( args, msg )

end

def auth( args, msg )
  args = args.strip 
  
end

"""
Hash that contains information about each command.
 An array that can be looked up by command name has three subvalues, a method
 reference, a short summary, and then and array of values to be sent out when
 the command itself is used with help, ie !help google.
"""
 $commands = { "help" => 
                [ self.method(:help), "Prints this message.",
                  ["!help <command>:", "  Prints a message about a command or displays all commands with a short summary."]
                ],
=begin
                "say" => 
                [ self.method(:say), "Finds something to say related to the specified word.",
                  ["!say <word or phrase> (optional chain length):", "  Builds something to say from the word provided. If provided, chain length specifies", 
                   "  If provided, chain length specifies the number of consecutive words per cycle; this increases coherency but reduces creativity.",
                  "  Default is random from " + $bot.set['logic']['minchainlength'].to_s + " to " + $bot.set['logic']['maxchainlength'].to_s + "." ]
                ],
                "sayl" => 
                [ self.method(:sayl), "Finds something to say related to a word similar to the one specified.",
                  ["!say <word or phrase> (optional chain length):", "  Builds something to say from a similar word to the one provided, accepting wildcards (%).",
                   "  Default wildcards (%word%) are always added unless another wildcard is specified.",
                   "  If provided, chain length specifies the number of consecutive words per cycle; this increases coherency but reduces creativity.", 
                   "  Default is random from " + $bot.set['logic']['minchainlength'].to_s + " to " + $bot.set['logic']['maxchainlength'].to_s + "." ]
                ],
=end
                "stats" =>
                [ self.method(:stats), "Returns some statistics about the database.",
                  ["!stats <optional topic> <optional param>:", "  Returns statistics about the optional topic, or the database if there are no arguments.",
                  "Currently the only other topic is w, which looks up statistics for the provided word." ]
                ],

                "shutup" =>
                [ self.method(:shutup), "The bot will remain quiet on this channel until woken.", 
                  ["!shutup*:", "  The bot will remain silent until !wakeup is used in this channel."]
                ],

                "speak" => 
                [ self.method(:speak), "The bot will speak in this channel again.",
                  ["!speak*:", "  The bot will speak in the current channel again if it was told to shutup before."]
                ],
                
                "auth" =>
                [ self.method(:auth), "Authenticate using the administrator password with the $bot.",
                  ["!auth <password> (optional host mask):", "  Authenticate with the bot to become an administrator using the admin password.",
                     "The host mask provided will modify your user."],
                ],
              }

"""
Wrapper for calling commands, just checks to see if the command exists first.
"""
def commandHandle(command, args, msg)
  if $commands.key?(command)
    $commands[command][0].call( args, msg )
  end
end

"""
Wrapper for some common say functions. Grabs the last argument,
if it's numeric, and returns it as level.
"""
def sayArgParser( args )
  args.strip!
  word = args
  level = Random.rand $bot.set['logic']['minchainlength']..$bot.set['logic']['maxchainlength']
 
  #Do a bit of black magic to separate a number argument at the end of a !say command from 
  # the requested word
  if args.match /[ ]+/
    args = args.split /[ ]+/
    args.delete ""
    if args[-1] =~ /[0-9]{1,2}/
      word = args[0...-1].join " "
      if args[-1].to_i <= 10 and args[-1].to_i > 0
        level = args[-1].to_i
      end
    end
  end
  
  return word, level
end
