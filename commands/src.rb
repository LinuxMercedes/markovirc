require 'cinch'
require 'json'

class Src 
  include Cinch::Plugin

  match /(src|source)( .+)?/, method: :execute

  def execute( m, name, args )
    if args != nil
      args = args.strip.to_i
      if args == 0 or args == nil
        args = 1
      end
    else
      args = 1
    end

    #We're looking for 1 (most recent message) 2 (two messages ago) or higher.
    if args > $bot.logs[m.channel].size or args < 1
      return
    end

    sent = $bot.logs[m.channel][-1*args]

    sent.chainids.map! { |w| w if w.size != 0  }

    chanid = m.getFirst_i "SELECT id FROM channels WHERE name=?", m.channel
    m.getFirst "INSERT INTO quotes (channelid, chain) VALUES ((SELECT id FROM channels WHERE name=?), ?)", 
                 [m.channel,JSON.generate(sent.chainids)]
    qid = m.getFirst_i "SELECT currval('quotes_id_seq')"

    m.reply "#{m.bot.set.quoteurl}#{qid.to_s}", true
  end
end

