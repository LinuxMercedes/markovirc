#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'pg'
require 'settingslogic'
require 'color-generator'
require 'cinch'
require_relative '/home/aaron/work/markovirc/utils.rb'
require_relative '/home/aaron/work/markovirc/modules/sentence.rb'

# Fake message class
class Message
  include DatabaseTools

  def initialize( )
  end
end

# Settings access
class Settings2 < Settingslogic
  source "/home/aaron/work/markovirc/config.yml"
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
def chain_to_word( chains )
  out = []
  chains.length.times.each do |i|
    sent = exec "SELECT wordid,nextwordid FROM chains WHERE id=$1", chains[i]
    out << sent[0].to_i
    if i == chains.length-1
      out << sent[1].to_i
    end
  end

  out
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
  $conn = PG.connect( :dbname => 'markovirc' )
  res = exec( "SELECT chain FROM quotes WHERE id=$1", [ params[:qid] ] )
  msg = Message.new
  
  out = ""
  chains = []
  generator = ColorGenerator.new saturation: 0.7, lightness: 0.5, seed: params[:qid].to_i
  chainids = []

  res.split( " " ).each do |r|
    chain = exec( "select wordid,textid from chains where id=$1", r )

    

    # keep the same color if we haven't changed text id's
    if chains.length > 0 and chain[1] == chains[-1][2] 
      chainids.last << r 
      chains << [ chains[-1][0], chain[0], chain[1] ]
    else
      chainids << [ r ]
      chains << [ generator.create_hex, chain[0], chain[1] ]
    end
  end
  
  tids = []
  wids = []

  # Push what marko said out.
  chains.map { |c| wids << c[1].to_i }

  sentence = Sentence.new msg, wids
  i = 0
  last = -1

  sentence.each do |word|
    word.suffix = "</font>"
    word.prefix = "<font color=\"#{chains[i][0]}\">" 

    tids << [ chains[i][0], chains[i][2].to_i ]
    i += 1
  end

  out += sentence.to_s + "<br />\n"

  frags = []
  colors = []

  #Get our source text's chain id's
  tids.uniq.each do |tid|
    sent = exec "SELECT id FROM chains WHERE textid=$1", tid[1]
    sent.delete( sent[-1] )
    frags << sent.flatten
    colors << tid[0]
  end

  colors.uniq!
  print colors, "\n\n"

  #Now that we have both the source text chain id's and the quote's
  #  we can flag text to be colored when it matches, in its entirety,
  #  a chunk of the source text. We tag it with the color it needs.

  frags.length.times.each do |i|
    ind = index_in frags[i], chainids[i] #Find the first occurance of this chain in this fragment & return index
    len = chainids[i].length

    frags[i] = Sentence.new msg, ( chain_to_word frags[i] ) 

    len.times do |j|
      #if j+ind >= frags[i].length 
      #  break
      #end
      frags[i][ind+j].prefix = "<font color=\"#{colors[i]}\">"
      frags[i][ind+j].suffix = "</font>" 
    end  

    out += frags[i].to_s + "<br />\n"

  end

  out
end
