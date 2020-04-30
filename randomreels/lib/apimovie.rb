class ApiMovie
    attr_reader :id, :title, :runtime, :poster, :rating, :genre, :release_date
    
    # below is a hash used for converting genre ids to text
    genres = {16 => "Animation", 28 => "Action", 12 => "Adventure", 35 => "Comedy", 80 => "Crime", 99 => "Documentary", 18 => "Drama", 10751 => "Family", 14 => "Fantasy", 36 => "History", 27 => "Horror", 10402 => "Music", 9648 => "Mystery", 10749 => "Romance", 878 => "Science Fiction", 10770 => "TV Movie", 53 => "Thriller", 10752 => "War", 37 => "Western"}
    
    def initialize(rawdat)
        # this little bit helps with ratings
        deets = Tmdb::Movie.detail(rawdat.id)
        
        @id = rawdat.id
        
        @title = deets.title
        
        @runtime = (deets.runtime / 60).to_s + "h " + (deets.runtime % 60).to_s + "m"
        
        if deets.poster_path != nil # in the case of the movie having no poster
            @poster = rawdat.poster_path
        else
            @poster = "[No Poster]"
        end
        
        @rating = Tmdb::Movie.releases(rawdat.id)
        @rating.delete_if {|a| a["iso_3166_1"] != "US" || a["certification"] == ""}
        if @rating[0] == nil # if no results are left, that means TMDb doesn't have an MPAA rating, so make it N/A
            @rating = "N/A"
        else                # otherwise, if TMDb has the MPAA rating, pull it out here
            @rating = rating[0]["certification"]
        end
        
        @genre = ""
        rawdat.genre_ids.each do |a| # loop to make clean genre list
            @genre = @genre + [a]
            if a != rawdat.genre_ids[rawdat.genre_ids.length - 1] # add a spacer if we haven't printed out the last genre yet
                print ", "
            end
        end
        
        @release_date = deets.release_date
    end
end