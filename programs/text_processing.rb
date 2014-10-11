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

        # Delete anything with our textid already
        conn.exec_params( "DELETE FROM chains WHERE textid=$1", [ id ] )

        # Grab the text
        txt = conn.exec_params( "SELECT text FROM text WHERE id=$1", [ id ] ).values.first.first

        txt = sever txt

        # Go through each wid and make sure we've got it
        words = conn.exec("SELECT id,word FROM words WHERE word in ('" + txt.map{ |w| conn.escape_string w }.join("','") + "')").values
        idhash = Hash.new

        words.each do |w|
          idhash[w[1]] = w[0]
        end

        # Prepare a query to insert tons of words if idhash.size != txt.size
        if txt.size != idhash.size
          insertwid = [ ]
          txt.each do |w|
            if not idhash.has_key? w and not insertwid.include? w
              insertwid << w 
            end
          end

          values = "('" + insertwid.map{ |w| conn.escape_string w }.join("'),('") + "')" 

          i = 0
          conn.exec("INSERT INTO words (word) VALUES #{values} RETURNING id").values.each do |w|
            idhash[insertwid[i]] = w.first
            i += 1
          end
        end

        # Now order everything properly
        oldtxt = txt
        txt = [ ]
        wids = [ ]

        txt.each do |w|
          wids << idhash[w]
        end

        # Prepare a query to slam into the database over and over
        name = "insert_#{id.to_s}"
        conn.prepare name, "INSERT INTO chains (wordid, textid, nextwordid) values ($1, #{id.to_s}, $2)"
        wids.size.times do |i|
          if i != sentence.size-1
            conn.exec_prepared name, [ wids[i], wids[i+1] ]
          else
            conn.exec_prepared name, [ wids[i], -1 ]
          end
        end

        # If we're still here we are finished
        conn.exec_params "UPDATE text SET processed=TRUE WHERE id=$1", [ id ]
        p "Finished processing #" + id.to_s
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
  def queue_size( )
    return @input_queue.size 
  end
end

# Our pool for future workers
$pool = TextPool.new worker_class: TextProcessor, size: 1
$check_conn = PG::Connection.open dbname: 'markovirc' 

timer = Workers::PeriodicTimer.new 1 do
  if $pool.queue_size < $pool.size
    # Check for new work
    texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE" ).values
    texts.flatten!

    texts.each do |i|
      if not $pool.queued.include? i
        $pool.enqueue :newtext, i
      end
    end
  end

  if $pool.queue_size > $pool.size and $pool.size < 2
    $pool.expand 1
  elsif $pool.queue_size == 0 and $pool.size > 1
    $pool.contract 1
  end
end

$pool.join
