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
  args = args.strip
  
  speak $db, msg, args
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
  end
  
  msg.reply "I know " + words.to_s + " words and " + contexts.to_s + " contexts for them, with an average context density of " + (contexts/words).floor.to_s + "."
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
                  ["!say <single word>:", "  Builds something to say from the word provided."]
                ],
                "stats" =>
                [ self.method(:stats), "Returns some statistics about the database.",
                  ["!stats <optional topic>:", "  Returns statistics about the optional topic, or the database."]
                ]
              }

"""
Wrapper for calling commands, just checks to see if the command exists first.
"""
def commandHandle(command, args, msg)
  if $commands.key?(command)
    $commands[command][0].call( args, msg )
  end
end
