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


    # group chains by source text for serialization
    chainids = []
    lasttid = nil
    $bot.logs[m.channel][-1*args].words.each do |w|
      if lasttid != w.textid
        chainids << []
      end
      lasttid = w.textid

      chainids.last << w.chainid
    end

    print "Chainids: ", chainids, "\n"
    print "Wids: ", $bot.logs[m.channel][-1*args].words.map { |w| w.wid }, "\n\n"

    chanid = m.getFirst_i "SELECT id FROM channels WHERE name=?", m.channel
    m.getFirst "INSERT INTO quotes (channelid, chain) VALUES ((SELECT id FROM channels WHERE name=?), ?)", 
                 [m.channel,JSON.generate(chainids)]
    qid = m.getFirst_i "SELECT currval('quotes_id_seq')"

    m.reply "#{m.bot.set.quoteurl}#{qid.to_s}", true
  end
end

