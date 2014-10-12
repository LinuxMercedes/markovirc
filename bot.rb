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
    c.plugins.plugins = [Say, SayL, Stats, Src, Log, RandomSpeech, Queued]
  end
end

$bot.start
