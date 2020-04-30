# initialize with tmdb api key
Tmdb::Api.key("092cb7163072d9e52ef2eb990db09fbd")

# get the apimovie class
require "#{Rails.root}/lib/apimovie.rb"
require "#{Rails.root}/lib/apimovietrack.rb"