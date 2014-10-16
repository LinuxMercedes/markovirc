module RegexParser
  def parseRegex( msgin )
    if msgin =~ /^(?<type>[u#w])?\/(?<regex>.*)\/(?<mod>[i!]+)?$/
      m = Regexp.last_match
      type = m[:type]
      mod = m[:mod]
      regex = m[:regex]
      type = "w" if type == "" or type == nil
      mod = "" if mod == nil
      mod = mod.split ""
      operator = ( mod.include?('!') ? '!' : '' ) + "~" + ( mod.include?('i') ? '*' : '' ) 

      return { regex: regex, type: type, modifier: mod, mod: mod, operator: operator, op: operator } 
    else
      return nil
    end
  end
end
