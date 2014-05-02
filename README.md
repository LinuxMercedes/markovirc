# Markovirc

Markovirc "Marko" is an IRC bot in Ruby that uses <a href="http://en.wikipedia.org/wiki/Markov_chain">Markov Chains</a> to generate text which appears human written. It gathers its source text from any channel it sits in, leading to humerous messages or drivel depending on quality. Markovirc drew deep inspiration from <a href="http://code.google.com/p/seeborg/">seeborg</a>.


## Installation

Markovirc has one primary dependency outside of its gems: PostgreSQL. Marko needs at least one database set up for its use, and this database can be shared by as many bots as your database daemon supports connections for. After installing git, postgres, and ruby, and the bundle gem start in marko's cloned directory. Run bundle to scrape the appropriate gems from the Rakefile:

    bundle install

Next setup your PostgreSQL database, for example:

    psql databasenamehere < base/db.sql
    
After this, copy down  the example config and edit it in your favorite editor. It should be fairly well documented.

    cp base/exampleconfig.yml config.yml
    
## Usage

Marko only supports a single command line parameter and it's optional, it is used to specify an alternate config yml which allows easier multiserver support.

    ruby bot.rb freenode.yml
    
    
