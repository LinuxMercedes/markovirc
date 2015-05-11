require 'settingslogic'

class Settings < Settingslogic
  if ARGV[0] == nil
    source "config.yml"
  else
    source ARGV[0]
  end
end
