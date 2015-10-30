
module DatabaseTools
  attr_accessor :sentence, :textid, :sourceid, :db

  @pool = @sentence = @textid = @sourceid = @db = nil
  @setup = false

  def setup
    return if @setup

    @setup = true
    self.exec \
      """
      CREATE OR REPLACE FUNCTION randomchain(int,text) 
      RETURNS int AS
      $$
        BEGIN
        EXECUTE 'CREATE TEMP TABLE temptable 
          ON COMMIT DROP
          AS (SELECT id
            FROM chains
            WHERE wid=' || $1 || $2
            || ');';

          RETURN (SELECT id
          FROM temptable
          OFFSET floor(RANDOM()*(
            SELECT count(id)
            FROM temptable
          ))
          LIMIT 1);
        END;
      $$ LANGUAGE plpgsql;
      """
  end

  def getFirst( query, args=[] )
    res = self.exec( query, args ).values.first

    if res.is_a? Array
      res = res.first
    end
  end

  #By default the type of everything returned is a string. 
  def getFirst_i( query, args=[] )
    res = self.exec( query, args ).values.first

    if res.is_a? Array
      res = res.first
    end

    res.to_i
  end

  # Wraps around getFirst_i to return a random int
  def getFirst_i_rand( selection, query, args )
    # Double our args since we are querying twice
    
    args = [ args ] if not args.is_a? Array

    nargs = Array.new args
    args.each do |a|
      nargs << a 
    end

    args = nargs
    
    self.getFirst_i( "SELECT #{selection} 
                      FROM #{query} 
                      OFFSET floor(RANDOM() * 
                        (SELECT count(*) 
                         FROM #{query})) 
                         LIMIT 1", args )
  end 

  # Wraps around getFirst_i to return a random int
  def getFirst_array_rand( selection, query, args )
    # Double our args since we are querying twice
    
    args = [ args ] if not args.is_a? Array

    nargs = Array.new args
    args.each do |a|
      nargs << a 
    end

    args = nargs
    
    r = self.getArray( "SELECT #{selection.join(',')} 
                        FROM #{query} 
                        OFFSET floor(RANDOM() * 
                          (SELECT count(*) 
                           FROM #{query})) 
                           LIMIT 1", args ) 
    
    r = r[0] if r.is_a? Array and r.size == 1
  end 

  def getArray( query, args )
    self.exec( query, args ).values
  end

  def escape_string( string )
    @pool.with do |conn|
      conn.escape_string( string )
    end
  end

  def exec( query, args=[] )
    if not args.is_a? Array
      args = [ args ]
    end

    # Escape args which contain ?
    args.map! { |a| a.to_s.gsub( /\?/, '\\?' ) }
    
    # Replace our ?'s with our args in order. Escape them and use exec
    # for compatibility with jruby_pg and pg.
    args.each do |arg|
      query.sub! /(?<!\\)\?/ do
        if @pool != nil
          @pool.with do |conn|
            "'#{conn.escape_string( arg )}'"
          end
        else
            "'#{$conn.escape_string( arg )}'"
        end
      end
    end

    # Now go back and change any escaped ?s to regular ?s (we escape already escaped ?s twice)
    query.gsub! /\\\?/, '?'

    $bot.debug "QUERY:\n#{query}"
    
    # Check whether we're using a pool or a global connection
    if @pool != nil
      @pool.with do |conn| 
        conn.exec query
      end
    else
      $conn.exec query
    end
  end
end
