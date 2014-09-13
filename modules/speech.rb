require_relative './chain.rb'

module Speech
  """
  Wrapper for some common say functions. Grabs the last argument,
  if it's numeric, and returns it as level.
  """
  def sayArgParser( args )
    args.strip!
    word = args
    level = nil
   
    #Do a bit of black magic to separate a number argument at the end of a !say command from 
    # the requested word
    if args.match /[ ]+/
      args = args.split /[ ]+/
      args.delete ""
      if args[-1] =~ /[0-9]{1,2}/
        word = args[0...-1].join " "
        level = args[-1].to_i
      end
    end
    
    return word, level
  end
end
