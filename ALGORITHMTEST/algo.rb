#
# NOTE: This is not going to be copied and pasted into the Rails app because that probably doesn't work.
#       This is just here in a separate folder so we all have a copy of the algorithm concept to look at for reference.
#

require 'themoviedb-api' # lets us use the TMDb api in this file -- do not change
Tmdb::Api.key("092cb7163072d9e52ef2eb990db09fbd") # api key so we get approval to use TMDb api -- do not change

curlist = Tmdb::Discover.movie(region: "US").results # initial movie candidate list
pastmovies = [] # list of movies the user has passed on
nosimilar = [] # 2d array of movies similar to ones the user has seen and disliked
yesimilar = [] # 2d array of movies similar to ones the user has seen and enjoyed
# below is a hash used for converting genre ids to text
genres = {16 => "Animation", 28 => "Action", 12 => "Adventure", 35 => "Comedy", 80 => "Crime", 99 => "Documentary", 18 => "Drama", 10751 => "Family", 14 => "Fantasy", 36 => "History", 27 => "Horror", 10402 => "Music", 9648 => "Mystery", 10749 => "Romance", 878 => "Science Fiction", 10770 => "TV Movie", 53 => "Thriller", 10752 => "War", 37 => "Western"}
chosen = false # shows whether or not the user has chosen a movie yet
pagenum = 1 # counts how many times the movie list has run empty (default: 1) to simplify similar movie tracking

# loop until a movie is chosen
while chosen == false
    # Get more detailed movie info to display
    # (Most of the info comes pretty straightforward, but the MPAA rating requires a weird backwards method as seen below)
    shownfilm = Tmdb::Movie.detail(curlist[0].id) # gets title, date, runtime, user score, genres, and poster
    rating = Tmdb::Movie.releases(curlist[0].id) # gets release dates/content ratings from all countries for this movie
    rating.delete_if {|a| a["iso_3166_1"] != "US" || a["certification"] == ""} # removes all blank and non-US results
    if rating[0] == nil # if no results are left, that means TMDb doesn't have an MPAA rating, so make it N/A
        rating = "N/A"
    else                # otherwise, if TMDb has the MPAA rating, pull it out here
        rating = rating[0]["certification"]
    end
    
    # Show the current movie (example below)
    # Movie Title (1900-01-01)
    # 1h 30m    [PG]    User Score: 67%
    # Animation | Mystery | Drama
    # Poster: fncni4eyreri
    puts shownfilm.title + " (" + shownfilm.release_date + ")"
    puts (shownfilm.runtime / 60).to_s + "h " + (shownfilm.runtime % 60).to_s + "m  [" + rating + "]  " + (shownfilm.vote_average * 10).to_s + "%"
    curlist[0].genre_ids.each do |a| # using curlist[0] for genres because the code is slightly cleaner this way
        print genres[a]
        if a != curlist[0].genre_ids[curlist[0].genre_ids.length - 1] # add a spacer if we haven't printed out the last genre yet
            print " | "
        end
    end
    if shownfilm.poster_path != nil # in the case of the movie having no poster
        puts "\nPoster: " + shownfilm.poster_path
    else
        puts "\n[No Poster]"
    end
    
    # Ask user what they think about this movie
    puts "What do you think?"
    
    # Get user response to question
    x = gets.chomp
    
    # Respond based on user input
    case x
        when "1" # Seen, liked
            # get list of similar movies so we know what to include
            # (the current movie is put on the list first so we know what movie the list is for)
            yesimilar[yesimilar.length] = [curlist[0]]
            for i in 1..pagenum # if we've already had the pagenum increase, get multiple pages so we can catch up
                yesimilar[yesimilar.length - 1].concat(Tmdb::Movie.similar(curlist[0].id, page: i).results)
            end
            
            # Remove any similar movies that haven't come out yet (but ignore ones with blank dates)
            yesimilar[yesimilar.length - 1].delete_if {|a| a.release_date != nil && a.release_date != "" && Date.parse(a.release_date) > Date.today}
            
            # If this is a foreign film, make sure the recommended movies are viewable in the US.
            # Without this, the user may get movies that are only available in foreign theaters.
            if curlist[0].original_language != "en"
                yesimilar[yesimilar.length - 1].delete_if {|a| Tmdb::Movie.releases(a.id).select! {|b| b["iso_3166_1"] == "US"} == nil}
            end
            
            # add similar movies list to candidate list
            curlist.concat(yesimilar[yesimilar.length - 1])
            
            # remove movies from candidate list that already blocked by nosimilar
            nosimilar.each do |a|
                curlist -= a
            end
            
            pastmovies[pastmovies.length] = curlist[0] # add current movie to passed movies
            curlist -= pastmovies # remove movies already passed by user (including this one)
            curlist.shuffle! # shuffle the list for that sweet variety
        when "2" # Seen, disliked
            # get list of similar movies so we know what to avoid
            # (the current movie is put on the list first so we know what movie the list is for)
            nosimilar[nosimilar.length] = [curlist[0]]
            for i in 1..pagenum # if we've already had the pagenum increase, get multiple pages so we can catch up
                nosimilar[nosimilar.length - 1].concat(Tmdb::Movie.similar(curlist[0].id, page: i).results)
            end
            
            # Some movies may share the same movies on their nosimilar lists.
            # This loop will remove any shared films to save space/time
            for i in 0..nosimilar.length-2 # using length-2 so we don't erase the most recent entry
                x = nosimilar[i][0] # the first value of a nosimilar array is always the movie it comes from, so save that
                nosimilar[i] = nosimilar[i] - nosimilar[nosimilar.length - 1] # remove any common movies
                nosimilar[i] = [x] + nosimilar[i] # put the saved value back in front so we know what movie this list is for
            end
            
            # remove similar movies from candidate list
            curlist -= nosimilar[nosimilar.length - 1]
            
            pastmovies[pastmovies.length] = curlist[0] # add current movie to passed movies
            curlist.delete_at(0) # delete current movie from candidate list
            curlist.shuffle! # shuffle the list for that sweet variety
        when "3" # Not interested
            pastmovies[pastmovies.length] = curlist[0] # add current movie to passed movies
            curlist.delete_at(0) # delete current movie from candidate list
        when "4" # Choose
            chosen = true
    end
    
    # while loop to replenish candidate list (if necessary) after a choice is made
    while curlist.length == 0 && chosen == false
        # advance the general page counter for search results
        pagenum += 1
        puts "recharging..."
        # get a new set of generic candidates
        # (this is done to avoid stagnating if a user hasn't liked any movies so far)
        curlist.concat(Tmdb::Discover.movie(region: "US", page: pagenum).results)
        
        # update similar list for good movies (if any have been found)
        if yesimilar.length > 0
            puts "adding good movies..."
            yesimilar.each do |a| 
                # To save space, we'll just change it to the most recent page since they already passed on the last 
                a = [a[0]] + Tmdb::Movie.similar(a[0].id, page: pagenum).results
                
                # Remove any similar movies that haven't come out yet
                yesimilar[yesimilar.length - 1].delete_if {|b| b.release_date != nil && Date.parse(b.release_date) > Date.today}
                
                # If this is a foreign film, make sure the recommended movies are viewable in the US.
                # Without this, the user may get movies that are only available in foreign theaters.
                if a[0].original_language != "en"
                    a.delete_if {|b| Tmdb::Movie.releases(b.id).select! {|c| c["iso_3166_1"] == "US"} == nil}
                end
                
                curlist.concat(a)
            end
        end
        
        # update similar list for bad movies (if any have been found)
        if nosimilar.length > 0
            puts "removing bad movies..."
            nosimilar.each do |a|
                # We won't use the space-saving move that we did in the last loop because we want to be sure to filter these movies out
                a.concat(Tmdb::Movie.similar(a[0].id, page: pagenum).results)
                curlist -= a
            end
        end
        
        # remove movies that have already been passed
        puts "cleaning..."
        curlist -= pastmovies
    end
end