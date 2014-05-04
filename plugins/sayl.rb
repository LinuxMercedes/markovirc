require 'cinch'

require_relative '../modules/speech.rb'
require_relative 'say.rb'

class SayL < Say
  include Cinch::Plugin
  include Speech

  match /(sayl) (.+)/, method: :execute
end

