def reqdir( dir )
  Dir.entries( dir ).each do |fn|
    if fn == '.' or fn == '..'
      next
    end

    if File.directory? fn
      next
    elsif File.fnmatch '*.rb', fn
      load File.dirname( __FILE__ ) + "/" + dir + fn
    end
  end
end

# Return a hash where a word => wid
def widHash( txt, conn )
  # Go through each wid and make sure we've got it
  words = conn.exec("SELECT id,word FROM words WHERE word in ('" + txt.uniq.map{ |w| conn.escape_string w }.join("','") + "')").values
  idhash = Hash.new

  words.each do |w|
    idhash[w[1]] = w[0]
  end


  idhash
end
