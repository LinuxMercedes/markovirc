require 'thread/pool'

pool = Thread.pool(4)

10.times {
    pool.process {
          sleep 2

              puts 'lol'
                }
}

pool.shutdown
