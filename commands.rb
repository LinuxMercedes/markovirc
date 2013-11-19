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

"""
Hash that contains information about each command.
 An array that can be looked up by command name has three subvalues, a method
 reference, a short summary, and then and array of values to be sent out when
 the command itself is used with help, ie !help google.
"""
 $commands = { "help" => 
              [ self.method(:help), "Prints this message.", 
                ["!help <command>:", "  Prints a message about a command or displays all commands with a short summary."] 
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
