require 'cinch'

class Queued
  include Cinch::Plugin

  match /queue(d)?/, method: :execute

  def execute( msg, args ) 
    # Get the number of items that are marked as processed=false
    processed = msg.getFirst_i "SELECT count(*) FROM text WHERE processed=FALSE"

    msg.reply( "There are currently #{processed.to_s} item#{"s" if processed != 1} queued for processing." )
  end
end
