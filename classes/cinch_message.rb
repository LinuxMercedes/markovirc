require 'cinch'
require_relative '../modules/databasetools.rb'

# Message is overloaded to serve as a database query handler.
class Cinch::Message
  include DatabaseTools
  alias_method :old_initialize, :initialize
  attr_accessor :pool

  def initialize( msg, bot )
    @pool = bot.pool

    old_initialize msg, bot
  end

  def useCommands?( )
    channel = $bot.set['channels'][self.channel]
    
    if channel.length == 0
      return true
    end

    if channel.include? 'silent' or channel.include? '-commands'
      false
    else
      true
    end
  end

  def canSpeak?( )
    channel = $bot.set['channels'][self.channel]

    if channel.include? 'silent' or channel.include? '-speak'
      false
    else
      true
    end
  end

  def canRespond?( )
    channel = $bot.set['channels'][self.channel]
    
    if ( channel.include? 'hilight' or ( not channel.include? 'silent' and not channel.include? '-speak' ) ) and self.message =~ /^#{$bot.nick}[:, ]+/  
      true
    else
      false
    end
  end
end

