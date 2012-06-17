from twisted.words.protocols import irc
from twisted.internet import reactor, protocol
from twisted.python import log

class Bot(irc.IRCClient):
  def __init__(self, nick, channel, filename):
    self.nickname = nick
    self.channel = channel
    self.filename = filename

  def connectionMade(self):
    irc.IRCClient.connectionMade(self)
    print "connected!"

  def connectionLost(self):
    irc.IRCClient.connectionLost(self)
    print "disconnected =/"

  def signedOn(self):
    self.join(self.channel)

  def joined(self, channel):
    print "Joined %s" % channel

  def privmsg(self, user, channel, msg):
    if channel == self.nickname:
      print "Msg from %s: %s" % (user, msg)
    else: #higlight
      print "%s says on %s: %s" % (user, channel, msg)

  def action(self, user, channel, msg):
    print "Action on %s by %s: %s" % (channel, user, msg)

  def irc_NICK(self, prefix, params):
    old_nick = prefix.split('!')[0]
    new_nick = params[0]
    print "%s is now known as %s" % (old_nick, new_nick)

class BotFactory(protocol.ClientFactory):
  def __init__(self, nick, channel, filename):
    self.channel = channel
    self.nick = nick
    self.filename = filename

  def buildProtocol(self, addr):
    p = Bot(self.nick, self.channel, self.filename)
    return p

  def clientConnectionLost(self, connector, reason):
    print "Disconnected %s" % reason
    connector.connect()

  def clientConnectionFaileD(self, connector, reason):
    print "connection failed", reason
    reactor.stop()

if __name__=="__main__":
  f = BotFactory("markovbot", "markovbot", "log.txt")
  reactor.connectTCP("irc.freenode.net", 6667, f)

  reactor.run()
