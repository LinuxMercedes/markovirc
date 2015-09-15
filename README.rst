=========
Markovirc
=========

Markovirc "Marko" is an IRC bot in Ruby that uses `Markov Chains <http://en.wikipedia.org/wiki/Markov_chain>`_ to generate text which appears human written. It gathers its source text from any channel it sits in, leading to humerous messages or drivel depending on quality. Markovirc drew deep inspiration from `seeborg <http://code.google.com/p/seeborg/>`_.

Installation
------------

Markovirc has one primary dependency outside of its gems: PostgreSQL. Marko needs at least one database set up for its use, and this database can be shared by as many bots as your database daemon supports connections for. After installing git, postgres, and ruby, and the bundle gem start in marko's cloned directory. Run bundle to scrape the appropriate gems from the Rakefile:

.. code:: bash

    bundle install

Next setup your PostgreSQL database, for example:

.. code:: bash

    psql databasenamehere < base/db.sql
    
After this, copy down  the example config and edit it in your favorite editor. It should be fairly well documented.

.. code:: bash

    cp base/exampleconfig.yml config.yml
    
Usage
-----

Marko only supports a single, optional command line parameter. The first argument is used to specify an alternate config yml which allows easier multiserver support.

.. code:: bash

    ruby bot.rb [config file; default: config.yml] 

Text Processing
***************

Previously, Marko processed all new messages on a new thread (with a GIL). When the primary instance of Marko was moved to over 60 channels, a lot of database action was conflicting and causing table locks. This, in turn, spawned many threads which all waited on each other progressively to finish. It quickly became benefical to have a single, separate program handle learning.

Text processing handles the processing of text logged from the IRC bot instance. It individually processes each line asynchronously from the bot, and queues it up in an internal thread pool. It can optionally be ran with jruby (which requires you to install pg_jruby).

.. code:: bash

    cd programs
    ruby text_processing.rb [config file; default: ../config.yml] [number of workers; default: 5]
