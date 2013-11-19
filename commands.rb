#Master file for commands

def help( args, msg )
  msg.reply args
end

$commands = { "help" => self.method(:help) }

def commandHandle(command, args, msg)
  
  $commands[command].call( args, msg )
end
