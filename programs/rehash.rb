require 'thread/pool'
require 'cinch'
require 'pg'
require 'connection_pool'

require_relative '../modules/sentence.rb'
require_relative '../utils.rb'

$db = ConnectionPool.new( size: 10, timeout: 20 ) { PG::Connection.open( :dbname => 'markovirc' ) } 

pool = Thread.pool 10
texts = 0
textcontents = ""

$db.with do |conn|
  conn.exec "TRUNCATE TABLE chains"
  conn.exec "ALTER SEQUENCE words_id_seq RESTART"
  conn.exec "ALTER SEQUENCE chains_id_seq RESTART"
  conn.exec "TRUNCATE TABLE words"
  texts = conn.exec( "SELECT id,text FROM text" ).values
end

$last = -1 

texts.each do |txt|
  pool.process do
    $db.with do |conn|
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

pool.shutdown
