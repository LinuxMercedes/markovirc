require 'cinch'
require 'pg'

require_relative "utils.rb"

$bot = Markovirc.new do
  configure do |c|
    c.server = self.set['server']
    c.channels = self.set['channels'].keys
    c.nick = self.set['nick']
    c.user = self.set['user'] 
  end
                                
  on :message, /^!([a-z]*)(.*)/i do |msg, command, args|
    $bot.pool.with do |con|
      msg.db = con
      if msg.useCommands?
        commandHandle command, args, msg
      end
    end
  end
  
  on :message, /^[^!]/ do |msg|
    $bot.pool.with do |con|
      msg.db = con
      logHandle msg
      if msg.canSpeak? or msg.canRespond? 
        speakRandom msg
      end
    end
  end
end

require_relative 'commands.rb'
require_relative 'logic.rb'
require_relative 'sentence.rb'
require_relative 'word.rb'

$bot.start
