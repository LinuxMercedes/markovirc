require 'pg'
require 'workers'
require 'cinch'

require_relative '../modules/sentence.rb'
require_relative '../utils.rb'

class TextProcessor < Workers::Worker
  private
  def process_event( event )
    case event.command
    when :newtext
      begin
        # New id is data
        id = event.data

        # Open our own connection 
        conn = PG::Connection.open dbname: 'markovirc' 

        # Grab the text
        txt = conn.exec_params( "SELECT text FROM text WHERE id=$1", [ id ] ).values.first.first

        out = sever txt

        # Go through each wid and make sure we've got it
        sentence = [ ]
        out.each do |word|
          wid = ( conn.exec_params "SELECT id FROM words WHERE word=$1", [ word ] ).values.first.first
          
          if wid == nil
            conn.exec_params "INSERT INTO words (word) VALUES ($1)", [ word ]
            wid = ( conn.exec_params "SELECT id FROM words WHERE word = $1", [ word ] ).values.first.first.to_i
          else
            wid = wid.to_i
          end
          sentence << wid
        end

        # Prepare a query to slam into the database over and over
        name = "insert_#{id.to_s}"
        conn.prepare name, "INSERT INTO chains (wordid, textid, nextwordid) values ($1, #{id.to_s}, $2)"
        sentence.size.times do |i|
          if i != sentence.size-1
            conn.exec_prepared name, [ sentence[i], sentence[i+1] ]
          else
            conn.exec_prepared name, [ sentence[i], -1 ]
          end
        end

        # If we're still here we are finished
        conn.exec_params "UPDATE text SET processed=TRUE WHERE id=$1", [ id ]
        print "Finished processing #", id, "\n"
      end
    end
  end
end

class TextPool <  Workers::Pool
  attr_accessor :queued

  def initialize( options = { } )
    @queued = [ ]
    super options 
  end
  def enqueue( command, data=nil )
    @queued << data

    super command, data
  end
end

# Our pool for future workers
$pool = TextPool.new worker_class: TextProcessor, size: 1
$check_conn = PG::Connection.open dbname: 'markovirc' 

timer = Workers::PeriodicTimer.new 1 do
  # Check for new work
  print "Checking\n"
  texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE" ).values
  texts.flatten!

  print "No work...\n\n" if texts.size == 0

  texts.each do |i|
    if not $pool.queued.include? i
      $pool.enqueue :newtext, i
    end
  end
end

$pool.join

=begin
texts.each do |txt|
  pool.process do
  end
end

pool.shutdown
=end
