class Song < ActiveRecord::Base
  belongs_to :mixtape

  attr_accessible :name, :artist, :album, :track_number, :duration, :file, :cover_art
end
