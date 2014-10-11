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
        puts "New text! #{event.data}"
        break
        id = txt[0] 
        txt = txt[1]

        percent = id.to_f/(texts.length-1)*100
        res = percent.round 0
        if res > $last
          print res, "%\n"
          $last = res 
        end

        out = sever txt
        sentence = []
        out.each do |word|
          wid = ( conn.exec_params "SELECT id FROM words WHERE word=$1", [word] ).values 
          wid = wid[0]
          
          if wid == nil
            while wid == nil
              conn.exec_params "INSERT INTO words (word) VALUES ($1)", [word]
              wid = ( conn.exec_params "SELECT id FROM words WHERE word = $1", [word] ).values
              wid = wid[0][0].to_i
            end
          else
            wid = wid[0].to_i
          end
          sentence << wid
        end

        sentence.size.times do |i|
          if i != sentence.size-1
            conn.exec_params "INSERT INTO chains (wordid,textid,nextwordid) VALUES ($1,$2,$3)", [sentence[i], id, sentence[i+1]]
          else
            conn.exec_params "INSERT INTO chains (wordid,textid) VALUES ($1,$2)", [sentence[i], id]
          end
        end
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
$pool = TextPool.new worker_class: TextProcessor
$check_conn = PG::Connection.open( :dbname => 'markovirc', :size => 1 ) 

timer = Workers::PeriodicTimer.new 1 do
  # Check for new work
  print "Checking"
  texts = $check_conn.exec( "SELECT id FROM text WHERE processed=FALSE" ).values
  texts.flatten!

  print "No work..." if texts.size == 0

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
