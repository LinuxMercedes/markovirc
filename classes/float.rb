# Overload float with an option for significant figure rounding.
# We use this in !stat for good wid ratios.
class Float
  def sigfig(signs)
    Float("%.#{signs}g" % self)
  end
end
