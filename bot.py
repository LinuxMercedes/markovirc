from twisted.words.protocols import irc
from twisted.internet import reactor, protocol
from twisted.python import log

class Bot(irc.IRCClient):
  def __init__(self, handler, nick, channel, filename):
    self.handler = handler
    self.nickname = nick
    self.channel = channel
    self.filename = filename

  def connectionMade(self):
    irc.IRCClient.connectionMade(self)
    self.handler.connected()

  def connectionLost(self):
    irc.IRCClient.connectionLost(self)
    self.handler.disconnected()

  def signedOn(self):
    self.join(self.channel)
    self.handler.signedOn()

  def joined(self, channel):
    self.handler.joined(channel)

  def privmsg(self, user, channel, msg):
# TODO: Make user pretty/object
    if channel == self.nickname:
      self.handler.privmsg(user, msg)
    else: 
      self.handler.chanmsg(user, channel, msg)

  def action(self, user, channel, msg):
    self.handler.action(user, channel, msg)

  # Do I need this? Methinks not.
  def irc_NICK(self, prefix, params):
    old_nick = prefix.split('!')[0]
    new_nick = params[0]
    print "%s is now known as %s" % (old_nick, new_nick)

class BotFactory(protocol.ClientFactory):
  def __init__(self, handler, nick, channel, filename):
    self.handler = handler
    self.channel = channel
    self.nick = nick
    self.filename = filename

  def buildProtocol(self, addr):
    p = Bot(self.handler, self.nick, self.channel, self.filename)
    return p

  def clientConnectionLost(self, connector, reason):
    print "Disconnected %s" % reason
    connector.connect()

  def clientConnectionFaileD(self, connector, reason):
    print "connection failed", reason
    reactor.stop()

def start(handler, nick, channel, server, logfile, port=6667):
  f = BotFactory(handler, nick, channel, logfile)
  reactor.connectTCP(server, port, f)
  reactor.run()
