#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'pg'
require 'settingslogic'
require 'color-generator'
require 'cinch'
require 'json'
require_relative '../utils.rb'
require_relative '../classes/sentence.rb'
require_relative '../modules/databasetools.rb'

set :bind, '0.0.0.0'

# Fake message class
class Message
  include DatabaseTools
end

# Settings access
class Settings2 < Settingslogic
  source "../config.yml"
end

$set = Settings2.new

def exec( query, variables )
  if not variables.is_a? Array
    variables = [ variables ]
  end

  res = $conn.exec_params( query, variables ).values
 
  while res.is_a? Array and res.length == 1 
    res = res[0]
  end

  res
end

# When tested in the past, it always returns wordid's in order
# Translate a list of chain id's into wordid's
def chain_to_word( chains )
  chains.map { |c| exec( "SELECT wid FROM chains WHERE id=$1", c ).to_i }
end


def index_in( within, fragment )
  start = -1
  j = 0
  within.length.times.each do |w|
    if j == fragment.length-1
      break    
    elsif fragment[j] == within[w]
      if start == -1
        start = w
      end
      j += 1
    elsif fragment[j] != within[w]
      start = -1
      j = 0
    end
  end
  
  if start != -1 and j != fragment.length-1
    start = -1
  end

  start
end

get '/src/' do
  'There\'s nothing of note here yet.'
end

get '/src/:qid' do
  if params[:qid] != params[:qid].to_i.to_s or params[:qid].to_i < 0
    "QID Must be an integer that's greater than 0."
  else
    $conn = PG.connect( :dbname => 'markovirc' )
    # This gets our string of chain id's
    res = exec( "SELECT chain FROM quotes WHERE id=$1", [ params[:qid] ] )
    res = JSON.parse res
    msg = Message.new

    out = ""
    chains = [] # Stores a 2d-array of [ [ word color, word, text source ], ... ]
    tids = []
    colors = Hash.new # Stores colors in order of source id for easy zipping in
    generator = ColorGenerator.new saturation: 0.7, lightness: 0.5, seed: params[:qid].to_i

    res.length.times.each do |chn|
      chains << []
      tid = 0
      color = generator.create_hex

      res[chn].each do |r|
        chain = exec( "select wid,tid from chains where id=$1", r )

        colors[chn] = color
        tid = chain[1]
        chains.last << [ color, chain[0], chain[1] ]
      end
      tids << tid 
    end

    wids = []
    tids_index = Array.new(tids)
    tids.uniq!

    # Push what marko said out.
    chains.map { |c| c.map { |d| wids << d[1].to_i } }

    print "wids in: " , wids, "\n\n"
    sentence = Sentence.new msg, wids
    i = 0

    flatchains = chains.flatten
    sentence.each do |word|
      word.suffix = "</font>"
      word.prefix = "<font color=\"#{flatchains[i*3]}\">" 
      i += 1
    end

    out += sentence.to_s + "<br />\n<br />\n<br />"

    srctext = Hash.new # Stores our original source text (eventually Sentences) for later

    #Get our source text's chain id's
    tids.each do |tid|
      sent = exec "SELECT id FROM chains WHERE tid=$1 ORDER BY id ASC", tid
      sent.delete( sent[-1] )
      sent.flatten! if sent.is_a? Array
      srctext[tid] = sent
    end

    maptidtosentence = Hash.new    # textid map to sentence class
    maptidtodetails  = Hash.new    # textid map to [username, channel] ids

    #Now that we have both the source text chain id's and the quote's
    #  we can flag text to be colored when it matches, in its entirety,
    #  a chunk of the source text. We tag it with the color it needs.

    res.length.times.each do |i|
      tid = tids_index[i]
      print "TID: ", tid, "\n"
      print "Before srctext2wid, srctext: ", srctext[tid], "\n", res[i], "\n\n"
      if not maptidtosentence.has_key? tid
        srctext[tid] = chain_to_word srctext[tid]
        print srctext[tid], "\n\n"
      end
      res[i] = chain_to_word res[i]

      print "After srctext2wid, srctext: ", srctext[tid], "\n", "res: ", res[i], "\n"

      ind = index_in srctext[tid], res[i] #Find the first occurance of this chain in this fragment & return index
      len = res[i].length
      if res.length != i+1
        len -= 1
      end
      #print "i: " + i.to_s + "\tind: " + ind.to_s + "\tlen: " + len.to_s + "\n\n"

      if not maptidtosentence.has_key? tid
        maptidtosentence[tid] = Sentence.new msg, srctext[tid] 

        # Fill in information about the source user
        chanid, userid = exec( "SELECT channelid,userid FROM sources WHERE id=(SELECT sourceid FROM text WHERE id=$1)", tid )
        username = exec( "SELECT hostmask FROM users WHERE id=$1", userid )
        
        #Limit username
        if username.length > 25
          username = username[0..25].gsub(/\s\w+\s*$/, "") + "..."
        end

        channel = exec( "SELECT name FROM channels WHERE id=$1", chanid )
        maptidtodetails[tid] = [ username, channel ] 
      end

      len.times do |j|
        #if j+ind >= srctext[i].length 
        #  break
        #end
        print "maptidtosentence @ tid: ", maptidtosentence[tid], " maptidtosentence @ tid @ ind+j:\n "
        maptidtosentence[tid][ind+j].prefix = "<font color=\"#{colors[i]}\">"
        maptidtosentence[tid][ind+j].suffix = "</font>" 
      end  
    end

    out += "<table cellspacing=\"5\">"
    maptidtosentence.values.each do |sourcesentence|
      out += "<tr>"

      ind = maptidtosentence.key sourcesentence
      out += "<td>" + maptidtodetails[ind][0] + "</td>" + "<td>" + maptidtodetails[ind][1] + "</td>" 
             + "<td>" + src.to_s + "</td>\n"

      out += "</tr>"
    end
    out += "</table>"

  out
  end
end
