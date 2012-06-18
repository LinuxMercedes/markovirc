import bot
import PrintHandler

if __name__=="__main__":
  ph = PrintHandler.PrintHandler()
  bot.start(ph, "markovbot", "markovbot", "irc.freenode.net", "log.txt")

