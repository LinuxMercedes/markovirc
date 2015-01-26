require 'cinch'
require 'fileutils'
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

# Configure Logging
if $bot.set.has_key? 'logging'
  dir = File.expand_path( "./logs/#{$bot.set['logging']}/" )
  FileUtils.mkdir_p dir
  file = "#{dir}/#{Time.now.strftime("%Y%m%d")}.log" 
  $bot.info "Logging to \"#{file}\"\n"
  $bot.loggers << Cinch::Logger::FormattedLogger.new( File.open( file, "a" ) )
  $bot.loggers.level = :debug
  $bot.info "="*40 + "\n"
  $bot.info "Started logging to \"#{file}\"\n"
  $bot.info "="*40 + "\n"
end

$bot.start
