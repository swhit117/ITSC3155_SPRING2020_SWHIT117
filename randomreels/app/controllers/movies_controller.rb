class MoviesController < ApplicationController
    def new
        @movie = ApiMovieTrack.new();
        # Movie.write_attribute(:title, "Avengers Endgame")
        redirect_to new_page_path
    end
end
