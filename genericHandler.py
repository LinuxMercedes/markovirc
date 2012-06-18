# A generic handler; does nothing

class GenericHandler(object):
  def connected():
    pass

  def disconnected():
    pass

  def signedOn():
    pass

  def joined(channel):
    pass

  def privmsg(user, msg):
    pass

  def chanmsg(user, channel, msg):
    pass

  def action(user, channel, msg):
    pass

