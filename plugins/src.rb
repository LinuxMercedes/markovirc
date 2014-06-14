require 'cinch'
require 'json'

class Src 
  include Cinch::Plugin
  include Source 

  match /(src|source) (.+)/, method: :execute

  def execute( m, name, args )
    args = args.strip.to_i
    
    #We're looking for 1 (most recent message) 2 (two messages ago) or higher.
    if args > $bot.logs[m.channel].size or args < 1
      return
    end

    sent = $bot.logs[m.channel][-1*args]
    sent.chainids.delete []

    chanid = m.getFirst_i "SELECT id FROM channels WHERE name=?", m.channel
    m.getFirst "INSERT INTO quotes (channelid, chain) VALUES (?, ?)", [chanid,JSON.generate(sent.chainids)]
    qid = m.getFirst_i "SELECT currval('quotes_id_seq')"

    m.reply "#{m.bot.set.quoteurl}#{qid.to_s}", true
  end
end

