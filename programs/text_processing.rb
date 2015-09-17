require 'pg'
require 'workers'
require 'settingslogic'

require_relative '../classes/sentence.rb'
require_relative '../modules/sever.rb'
require_relative '../classes/settings.rb'

# Don't buffer or wait to catch up.
$stdout.sync = false
# The amount of text we queue up for each thread
$numperthread = 100

#FIXME: These globals are terrible
if ARGV.size == 0
  $set = Settings.new('../config.yml')
else
  $set = Settings.new # class reads from command line
end

$lastwork = -1
if ARGV.size == 0
  $threads = 5
elsif ARGV.size == 2
  $threads = ARGV[1]
end

def nil_to_null str
  if str == nil
    "NULL"
  else
    str
  end
end

class TextProcessor < Workers::Worker

  attr_accessor :conn
  def initialize( options = {} )
    @conn = PG::Connection.open( dbname: $set['database'] )
    @conn.exec "PREPARE chain_insert (int,int,int) AS INSERT INTO CHAINS (wid,nextid,tid) VALUES ($1,$2,$3)" \
               + " RETURNING id"

    super options
  end

  private

  def event_handler( event )
    case event.command
    when :newtext
      begin
        # New id is data
        id = event.data

        # Set this line as processed
        @conn.exec( "UPDATE text SET processed=TRUE WHERE id=#{id.to_s}" )

        # Grab the text
        txt = @conn.exec( "SELECT text FROM text WHERE id=#{id.to_s}" ).values.first.first

        txt = sever txt
        if txt.size == 0
          exit
        end

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

        wids.flatten!

        lastcid = nil
        # Gives us consecuitive pairs
        wids.reverse.each do |wid|
          lastcid = @conn.exec("EXECUTE chain_insert(#{wid},#{nil_to_null(lastcid)},#{event.data.to_s})")[0]['id']
        end

        print "."
        $stdout.flush
      rescue Exception => e
        if e.to_s != "exit"
          @conn.exec "UPDATE text SET processed=FALSE WHERE id=#{event.data.to_s}"
          @conn.exec "DELETE FROM chains WHERE tid=#{event.data.to_s}"
        end
        print "\nError: ", e.to_s, "\n"
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
  if $pool.queue_size < $pool.size*$numperthread/10
    # Check for new work
    texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE LIMIT #{$threads.to_i*$numperthread}" ).values
    texts.flatten!

    left = $check_conn.exec( "SELECT count(*) FROM text WHERE processed=FALSE" ).values.first.first
    texts.each do |i|
      $pool.enqueue :newtext, i
    end
  end
end

# Our pool for future workers
$pool = TextPool.new( worker_class: TextProcessor, size: $threads.to_i )
# Pool to grab values to process
$check_conn = PG::Connection.open( dbname: $set['database'] )

begin
  $pool.join
rescue Exception => e
  print "Shutting down cleanly. Press ctrl+c again to force.\n"

  $pool.shutdown do
    Thread.current.conn.finish
  end

  timer.cancel

  $pool.join 1
  $check_conn.finish
end
