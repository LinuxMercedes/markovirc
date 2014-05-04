require 'cinch'
require 'pg'

require_relative "utils.rb"
reqdir "modules/"
reqdir "plugins/"

$bot = Markovirc.new do
  configure do |c|
    c.server = self.set['server']
    c.channels = self.set['channels'].keys
    c.nick = self.set['nick']
    c.user = self.set['user'] 
    c.plugins.plugins = [Say]
  end
                                
  on :message, /^!([a-z]*)(.*)/i do |msg, command, args|
    if msg.useCommands?
      commandHandle command, args, msg
    end
  end
  
  on :message, /^[^!]/ do |msg|
    logHandle msg
    if msg.canSpeak? or msg.canRespond? 
      speakRandom msg
    end
  end
end

require_relative 'commands.rb'
require_relative 'logic.rb'

$bot.start
