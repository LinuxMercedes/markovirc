# Intelligently split a sentence by punctuation, then split the individual spaces
# so we get words.
def sever( text )
  # For now, quotes are stripped since handling them is tricky.
  text.gsub! /"/, ""
  sentences = text.scan /([^\.!:\?,]+)([\.!\?:,]+)?/ 
  # If it's only punctuation, it returns nil
  sentences = [ text ] if sentences.size == 0

  sentences.flatten!
  sentences.compact!

  last = 0 
  while last != sentences.length
    last = sentences.length

    # Inspect for smashed urls
    sentences.length.times do |i|
      if sentences[i] =~ /^[\.!?:]+$/ and sentences.length > i+1 and sentences[i+1][0] !~ /[\s]/
        sentences[i-1] = sentences[(i-1)..(i+1)].join ''
        sentences.delete_at i
        sentences.delete_at i
        break 
      end
    end
  end

  sentences.map! { |x| x.split /\s+/ }
  sentences.flatten!
  sentences.delete_if { |x| x == "" }

  return sentences
end

