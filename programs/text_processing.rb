require 'pg'
require 'workers'
require 'cinch'

require_relative '../modules/sentence.rb'
require_relative '../utils.rb'

$lastwork = -1
if $ARGV.size == 0
  $threads = 5
else
  $threads = $ARGV[0]
end

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
        conn.exec( "DELETE FROM chains WHERE textid=#{id.to_s}" )

        # Grab the text
        txt = conn.exec( "SELECT text FROM text WHERE id=#{id.to_s}" ).values.first.first
        #print "TXT:", txt, "\n"

        txt = sever txt
        #print "TXT: ", txt, "\n"

        # Go through each wid and make sure we've got it
        words = conn.exec("SELECT id,word FROM words WHERE word in ('" + txt.uniq.map{ |w| conn.escape_string w }.join("','") + "')").values
        idhash = Hash.new

        words.each do |w|
          idhash[w[1]] = w[0]
        end

        # Prepare a query to insert tons of words if idhash.size != txt.size
        if txt.uniq.size != idhash.size
          insertwid = [ ]
          txt.each do |w|
            if not idhash.has_key? w and not insertwid.include? w
              insertwid << w 
            end
          end

          values = "('" + insertwid.map{ |w| conn.escape_string w }.join("'),('") + "')" 
          #print "VALUES: ", values, "\n"

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
        conn.exec "UPDATE text SET processed=TRUE WHERE id=#{id.to_s}"
        conn.close
      end
    end
  end
end

class TextPool <  Workers::Pool
  attr_accessor :queued

  DEFAULT_POOL_SIZE = 1

  def initialize( options = { } )
    super options 
    
    @queued = [ ]
  end
  def enqueue( command, data=nil )
    @queued << data

    super command, data
  end
  def queue_size( )
    return @input_queue.size 
  end
end

timer = Workers::PeriodicTimer.new 1 do
  if $pool.queue_size < $pool.size
    $rate = ( $threads.to_i * 50 ) / ( Time.now.to_f - $lastwork )
    $lastwork = Time.now.to_i
    # Check for new work
    texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE LIMIT #{$threads.to_i*100}" ).values
    texts.flatten!

    print "Current rate: ", $rate, " sentences/s\n"
    texts.each do |i|
      if not $pool.queued.include? i
        $pool.enqueue :newtext, i
      end
    end
  end
end

# Our pool for future workers
$pool = TextPool.new( worker_class: TextProcessor, size: $threads.to_i )
$check_conn = PG::Connection.open dbname: 'markovirc' 

$pool.join
