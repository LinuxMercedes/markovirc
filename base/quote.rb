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

def word_lookup( wid )
  exec( "SELECT word FROM words WHERE id=$1", wid )
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

  res.split( " " ).each do |r|
    chain = exec( "SELECT wordid,textid FROM chains WHERE id=$1", r )

    # Keep the same color if we haven't changed text id's
    if chains.length > 0 and chain[1] == chains[-1][2] 
      chains << [ chains[-1][0], chain[0], chain[1] ]
    else
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

    tids << [ chains[i][0], chains[i][2] ]
    i += 1
  end

  out += sentence.to_s + "<br />\n"

  last = -1
  i = 0
  # Now get our other source ids (text ids). Assume these text id's are in order.
  tids.uniq.each do |tid|
    sent = exec "SELECT wordid,nextwordid FROM chains WHERE textid=$1", tid[1]
    sent.flatten!.uniq!.map! { |c| c = c.to_i }
    sent.delete sent[-1]

    sent = Sentence.new msg, sent
    if last != -1
  
    else 
      sent.each do |word|
        if word.text == chains[i][1]
          word.prefix = "<font color=\"#{chains[i][0]}\""
          word.suffix = "</font>" 
          i += 1
        end
      end
    end

    out += sent.to_s + "<br />\n"
  end

  out
end
