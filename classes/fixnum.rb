# Formatting for commas, used for large numbers in stats
class Fixnum
  def commas( )
    s = self.to_s.reverse 

    # Follow, backwards, all groups of 3 numbers with a comma
    s.gsub( /([0-9]{3})/, "\\1," ).gsub( /,$/, "" ).reverse
  end
end

