require 'cinch'

class Join
  include Cinch::Plugin

  match /(join|query)\s*(.+)?/, method: :execute

  def execute( m, name, channel )
    return if not m.useCommands?

    if channel != nil
      $bot.set['channels'][channel] = []
      $bot.join channel
      m.reply "Joined #{channel}"
    else
      m.reply "I'm already here."
    end
  end

end

