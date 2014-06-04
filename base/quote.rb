#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'pg'
require 'settingslogic'


get '/src/' do
  'There\'s nothing of note here yet.'
end

get '/src/:qid' do
  'Here\'s your qid: ' + params[:qid].to_s

end
