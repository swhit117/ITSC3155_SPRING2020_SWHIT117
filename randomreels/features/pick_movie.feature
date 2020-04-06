Feature: Choose a movie to watch
  
  As a film enthusiast
  So that I can decide on what movie to watch
  I want to be able to filter out movies that I've liked/disliked or have no interest in
  
Scenario: As a film enthusiast, I want to filter out movies that I've already seen
  Given I am on the home page
  When I click on the "START" button
  Then I should be on the "How about..." page
  And I should see the "Pick" button
  And I should see the "Liked it" button
  And I should see the "Disliked it" button
  And I should see the "Not interested" button
  When I click on the "Not interested" button
  Then I should be on the "How about..." page
  # And I should have an entry in my previous movie array
  # And I should have NO entry in my liked and disliked similar movie arrays
  When I click on the "Liked it" button
  Then I should be on the "How about..." page
  # And I should have an entry in my liked similar movie array
  # And I should have NO entry in my disliked similar movie array
  When I click on the "Disliked it" button
  Then I should be on the "How about..." page
  # And I should have an entry in my disliked similar movie array