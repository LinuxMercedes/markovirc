require 'pg'
require 'workers'

require_relative '../modules/sentence.rb'
require_relative '../modules/sever.rb'

$stdout.sync = false

$lastwork = -1
if $ARGV == nil or $ARGV.size == 0
  $threads = 5
else
  $threads = $ARGV[0]
end

class TextProcessor < Workers::Worker
  def initialize( options = {} )
    @conn = PG::Connection.open dbname: 'markovirc'
    
    super options
  end

  private

  def process_event( event )
    case event.command
    when :newtext
      begin
        # New id is data
        id = event.data
        #print "ID: ", id, "\n"

        # Delete anything with our textid already
        @conn.exec( "DELETE FROM chains WHERE textid=#{id.to_s}" )

        # Set this line as processed
        @conn.exec( "UPDATE text SET processed=TRUE WHERE id=#{id.to_s}" )

        # Grab the text
        txt = @conn.exec( "SELECT text FROM text WHERE id=#{id.to_s}" ).values.first.first
        #print "TXT:", txt, "\n"

        txt = sever txt
        if txt.size == 0
          exit
          # Weird shit
        end
        #print "TXT: ", txt, "\n"

        # Go through each wid and make sure we've got it
        words = @conn.exec("SELECT id,word FROM words WHERE word in ('" + txt.uniq.map{ |w| @conn.escape_string w }.join("','") + "')").values
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

          values = "('" + insertwid.map{ |w| @conn.escape_string w }.join("'),('") + "')" 
          #print "VALUES: ", values, "\n"

          i = 0
          @conn.exec("INSERT INTO words (word) VALUES #{values} RETURNING id").values.each do |w|
            idhash[insertwid[i]] = w.first
            i += 1
          end
        end

        # Now order everything properly
        oldtxt = txt
        txt = [ ]
        wids = [ ]
        values = [ ]

        oldtxt.each do |w|
          wids << idhash[w]
        end

        # Prepare a query to slam into the database over and over
        wids.size.times do |i|
          if i != wids.size-1
            values << ("(" + [ wids[i], wids[i+1], id ].join(",") + ")" )
          else
            values << ("(" + [ wids[i], -1, id ].join(",") + ")" )
          end
        end

        values = values.join(",")
        @conn.exec "INSERT INTO chains (wordid, nextwordid, textid) VALUES #{values}"
        print "."
        $stdout.flush
      rescue Exception => e
        if e.to_s != "exit"
          @conn.exec "UPDATE text SET processed=FALSE WHERE id=#{event.data.to_s}"
        end
        #print "Error: ", e.to_s, "\n"
        print "!"
        $stdout.flush
      end
    end
  end
end

class TextPool <  Workers::Pool
  attr_accessor :queued

  DEFAULT_POOL_SIZE = $threads 

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
  if $pool.queue_size < $pool.size*10
    numperthread = 100
    #$rate = ( $threads.to_i * numperthread - $pool.queue_size ) / ( Time.now.to_f - $lastwork )
    #$lastwork = Time.now.to_i
    # Check for new work
    texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE LIMIT #{$threads.to_i*numperthread}" ).values
    texts.flatten!

    #print "\nCurrent rate: ", $rate, " sentences/s\n"
    #print "\Workers: ", $pool.size, "\n"
    left = $check_conn.exec( "SELECT count(*) FROM text WHERE processed=FALSE" ).values.first.first
    #print "Remaining: ", left, "\n\n"
    texts.each do |i|
      $pool.enqueue :newtext, i
    end
  end
end

# Our pool for future workers
$pool = TextPool.new( worker_class: TextProcessor, size: $threads.to_i )
$check_conn = PG::Connection.open dbname: 'markovirc' 

$pool.join
