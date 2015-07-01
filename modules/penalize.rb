module Penalize
  # This class acts as a module to tack on to chain

  # Calculate the penalty for a chain, store it on the chain.
  def calculate_penalty( m )
    @penalty = 0
    logicconfig = m.bot.set.logic
    
    # Handle underflow
    if @words.size < logicconfig.minwords
      @penalty += logicconfig.underflow
      m.bot.debug "Penalty added for being below the word limit, now: #{@penalty.to_s}\n"
    end

    # Handle overflow
    # LHS
    # Start at the far left and work until a word has seed == true
    count = 0
    @words.times.each do |i|
      last if @words[i].seed
      count += 1
    end

    if count > logicconfig.maxwords
      @penalty += ( count - logicconfig.maxwords ) * logicconfig.lhsoverflow
      m.bot.debug "Penalty added for max lhs, now: #{@penalty.to_s}\n"
    end

    # RHS
    count = 0
    @words.times.reverse.each do |i|
      last if @words[i].seed
      count += 1
    end

    if count > logicconfig.maxwords
      @penalty += ( count - logicconfig.maxwords ) * logicconfig.rhsoverflow
      m.bot.debug "Penalty added for max rhs, now: #{@penalty.to_s}\n"
    end

    
    # Do a return before calculating coherency if we're already at our limit

    # Coherency

    m.bot.debug "Penalty calculated: #{@penalty.to_s}\n"
  end

  # Throw away this chain
  def keep?( m )
    return true if m.bot.set.logic.maxpenalty < 0
    
    calculate_penalty( m ) if @penalty == nil

    return @penalty <= m.bot.set.logic.maxpenalty
  end
end
