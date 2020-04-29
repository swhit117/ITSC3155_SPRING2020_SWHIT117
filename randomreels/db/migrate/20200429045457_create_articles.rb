class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :runTime
      t.string :poster

      t.timestamps
    end
  end
end
