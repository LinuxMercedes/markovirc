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
    
  speak $db, msg, word, level
end

def sayl( args, msg )
  word, level = sayArgParser( args )
  
  if not word =~ /\%/
    word = "%#{word}%"
  end
  
  speak $db, msg, word, level, true
end

#Statistics
def stats( args, msg )
  args = args.strip
  
  if args == ""
    args = "db"
  end
  
  if args == "db"
    words = $db.get_first_value "SELECT count(*) FROM words"
    contexts = $db.get_first_value "SELECT count(*) FROM chains"
  
    msg.reply "I know " + words.to_s + " words and " + contexts.to_s + " contexts for them, with an average context density of " \
      + (contexts/words).floor.to_s + "."
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
                "say" => 
                [ self.method(:say), "Finds something to say related to the specified word.",
                  ["!say <word or phrase> (optional chain length):", "  Builds something to say from the word provided. If provided, chain length specifies", 
                   "  If provided, chain length specifies the number of consecutive words per cycle; this increases coherency but reduces creativity. Default is 3." ]
                ],
                "sayl" => 
                [ self.method(:sayl), "Finds something to say related to a word similar to the one specified.",
                  ["!say <word or phrase> (optional chain length):", "  Builds something to say from a similar word to the one provided, accepting wildcards (%).",
                   "  Default wildcards (%word%) are always added unless another wildcard is specified.",
                   "  If provided, chain length specifies the number of consecutive words per cycle; this increases coherency but reduces creativity. Default is 3." ]
                ],
                "stats" =>
                [ self.method(:stats), "Returns some statistics about the database.",
                  ["!stats <optional topic>:", "  Returns statistics about the optional topic, or the database."]
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
                [ self.method(:auth), "Authenticate using the administrator password with the bot.",
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
  word = args.strip
  level = $set.chainlength
  
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
