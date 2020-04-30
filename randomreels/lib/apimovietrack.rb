class ApiMovieTrack
    
    # stuff
    attr_reader :curlist, :candidates, :pastmovies, :yesimilar, :nosimilar, :pagenum
    
    # --------------------------------------------------------------------------
    # initializer
    # --------------------------------------------------------------------------
    def initialize()
        # get a preliminary list
        curlist = Tmdb::Discover.movie(region: "US").results
        
        # make these into an array of ApiMovie objects
        @candidates = []
        curlist.each do |a|
            @candidates.push(ApiMovie.new(a))
        end
        
        # make learning lists and pagenum
        @pastmovies = []
        @yesimilar = []
        @nosimilar = []
        @pagenum = 1
    end
    
    # --------------------------------------------------------------------------
    # method to show the next movie candidate
    # --------------------------------------------------------------------------
    def showFirst()
        return @candidates[0]
    end
    
    # --------------------------------------------------------------------------
    # method to get more candidates (and update the other lists) if they run out
    # --------------------------------------------------------------------------
    def refreshLists()
        while @candidates.length == 0
            # advance the general page counter for search results
            @pagenum += 1
            
            # PART 1: get a new set of generic candidates
            # (this is done to avoid stagnating if a user hasn't liked any movies so far)
            curlist = Tmdb::Discover.movie(region: "US", page: @pagenum).results
            curlist.each do |a| # make these into an array of ApiMovie objects
                @candidates.push(ApiMovie.new(a))
            end
        
            # PART 2: update similar list for good movies (if any have been found)
            if @yesimilar.length > 0
                @yesimilar.each do |a| 
                    # To save space, we'll just change it to the most recent page since they already passed on the 
                    keymovie = a[0]
                    newYes = Tmdb::Movie.similar(a[0].id, page: @pagenum).results
                    
                    # Remove any movies that haven't come out yet
                    newYes.delete_if {|b| b.release_date != nil && Date.parse(b.release_date) > Date.today}
                    
                    # If this is a foreign film, make sure the recommended movies are viewable in the US.
                    # Without this, the user may get movies that are only available in foreign theaters.
                    if a[0].original_language != "en"
                        newYes.delete_if {|b| Tmdb::Movie.releases(b.id).select! {|c| c["iso_3166_1"] == "US"} == nil}
                    end
                    
                    # make these into an array of ApiMovie objects
                    a = [keymovie]
                    newYes.each do |b|
                        a.push(ApiMovie.new(b))
                    end
                    
                    # add results to candidate list
                    @candidates.concat(a)
                end
            end
        
            # PART 3: update similar list for bad movies (if any have been found)
            if @nosimilar.length > 0
                @nosimilar.each do |a|
                    # We won't use the space-saving move that we did in the last loop because we want to be sure to filter these movies out
                    newNo = Tmdb::Movie.similar(a[0].id, page: @pagenum).results
                    
                    # make these into an array of ApiMovie objects
                    newNo.each do |b|
                        a.push(ApiMovie.new(b))
                    end
                    
                    # remove them bad films (if any were suggested earlier and weren't caught before now)
                    @candidates -= a
                end
            end
        
            # remove movies that have already been passed
            @candidates -= @pastmovies
        end
    end
    
    # --------------------------------------------------------------------------
    # method called by clicking "more like this"
    # --------------------------------------------------------------------------
    def moreLikeThis()
        # get list of similar movies so we know what to include
        # (the current movie is put on the list first so we know what movie the list is for)
        @yesimilar[@yesimilar.length] = [@candidates[0]]
        newYes = []
        for i in 1..@pagenum # if we've already had the pagenum increase, get multiple pages so we can catch up
            newYes.concat(Tmdb::Movie.similar(@candidates[0].id, page: i).results)
        end
        
        # Remove any similar movies that haven't come out yet (but ignore ones with blank dates)
        newYes.delete_if {|a| a.release_date != nil && a.release_date != "" && Date.parse(a.release_date) > Date.today}
        
        # If this is a foreign film, make sure the recommended movies are viewable in the US.
        # Without this, the user may get movies that are only available in foreign theaters.
        if @candidates[0].original_language != "en"
            newYes.delete_if {|a| Tmdb::Movie.releases(a.id).select! {|b| b["iso_3166_1"] == "US"} == nil}
        end
        
        # make these into an array of ApiMovie objects
        newYes.each do |a|
            @yesimilar[@yesimilar.length - 1].push(ApiMovie.new(a))
        end
        
        # add similar movies list to candidate list
        @candidates.concat(@yesimilar[@yesimilar.length - 1])
        
        # remove movies from candidate list that already blocked by nosimilar
        @nosimilar.each do |a|
            @candidates -= a
        end
        
        @pastmovies[@pastmovies.length] = @candidates[0] # add current movie to passed movies
        @candidates -= @pastmovies # remove movies already passed by user (including this one)
        @candidates.shuffle! # shuffle the list for that sweet variety
        
        # call refresher to ensure against crashes
        self.refreshLists()
    end
    
    # --------------------------------------------------------------------------
    # method called by clicking "less like this"
    # --------------------------------------------------------------------------
    def lessLikeThis()
        # get list of similar movies so we know what to avoid
        # (the current movie is put on the list first so we know what movie the list is for)
        @nosimilar[@nosimilar.length] = [@candidates[0]]
        newNo = []
        for i in 1..@pagenum # if we've already had the pagenum increase, get multiple pages so we can catch up
            newNo.concat(Tmdb::Movie.similar(@candidates[0].id, page: i).results)
        end
        
        # make these into an array of ApiMovie objects
        newNo.each do |a|
            @nosimilar[@nosimilar.length - 1].push(ApiMovie.new(a))
        end
        
        # Some movies may share the same movies on their nosimilar lists.
        # This loop will remove any shared films to save space/time
        for i in 0..@nosimilar.length-2 # using length-2 so we don't erase the most recent entry
            x = @nosimilar[i][0] # the first value of a nosimilar array is always the movie it comes from, so save that
            @nosimilar[i] = @nosimilar[i] - @nosimilar[@nosimilar.length - 1] # remove any common movies
            @nosimilar[i] = [x] + @nosimilar[i] # put the saved value back in front so we know what movie this list is for
        end
        
        # remove similar movies from candidate list
        @candidates -= @nosimilar[@nosimilar.length - 1]
        
        @pastmovies[@pastmovies.length] = @candidates[0] # add current movie to passed movies
        @candidates.delete_at(0) # delete current movie from candidate list
        @candidates.shuffle! # shuffle the list for that sweet variety
        
        # call refresher to ensure against crashes
        self.refreshLists()
    end
    
    # --------------------------------------------------------------------------
    # method called by clicking "not interested"
    # --------------------------------------------------------------------------
    def notInterested()
        # add current movie to passed movies
        @pastmovies[@pastmovies.length] = @candidates[0]
        
        # delete current movie from candidate list
        @candidates.delete_at(0)
        
        # call refresher to ensure against crashes
        self.refreshLists()
    end
    
end