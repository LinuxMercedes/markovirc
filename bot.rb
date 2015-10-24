require 'cinch'
require 'fileutils'
require 'pg'

require_relative "utils.rb"
reqdir "modules/"
reqdir "commands/"
reqdir "classes/"

$bot = Markovirc.new do
  configure do |c|
    c.server = self.set['server']
    c.channels = self.set['channels'].keys
    c.nick = self.set['nick']
    c.user = self.set['user'] 
    c.port = self.set['port']
    if self.set.has_key? 'pass'
      c.password = self.set['pass']
    end

    c.ssl.use = self.set['ssl'] or false
    c.ssl.verify = self.set['sslverify'] or true
    c.plugins.plugins = [Say, Stats, Log, RandomSpeech, Queued, Quiet, Speak, Join, Part, Src, SayUser]
  end
end

# Configure Logging
if $bot.set.has_key? 'logging'
  dir = File.expand_path( "./logs/#{$bot.set['logging']}/" )
  FileUtils.mkdir_p dir
  file = "#{dir}/#{Time.now.strftime("%Y%m%d")}.log" 
  $bot.info "Logging to \"#{file}\""
  $bot.loggers << Cinch::Logger::FormattedLogger.new( File.open( file, "a" ) )
  $bot.loggers.level = :debug
  $bot.info "="*40 
  $bot.info "Started logging to \"#{file}\""
  $bot.info "="*40 
end

begin
  $bot.start
rescue Exception => e
  $bot.debug "Shutting down cleanly. Press ctrl+c again to force."
  $bot.quit "User quit"
  $bot.pool.shutdown { |c| c.finish }

  sleep 1 # Could wait on $bot.quitting, but it never flips
end
