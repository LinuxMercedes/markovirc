require 'cinch'

class Part
  include Cinch::Plugin

  match /(part|leave)\s*(.+)?/, method: :execute

  def execute( m, name, channel )
    return if not m.useCommands?

    if channel != nil
      $bot.part channel
      m.reply "Left #{channel}"
    else
      $bot.part m.channel
    end
  end
end

