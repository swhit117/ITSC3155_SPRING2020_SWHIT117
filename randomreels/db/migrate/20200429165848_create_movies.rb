class CreateMovies < ActiveRecord::Migration[5.2]
  def change
    create_table :movies do |t|
      t.string :title
      t.string :runTime
      t.string :poster
      t.string :rating
      t.string :genre
      t.string :releaseDate

      t.timestamps
    end
  end
end
