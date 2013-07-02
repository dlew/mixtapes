require 'zip/zip'

class Mixtape < ActiveRecord::Base
  has_many :songs, :order => 'track_number, id'
  has_many :comments, :order => 'created_at'
  belongs_to :user

  attr_accessible :name, :cover

  default_scope order('name')

  # Only get Mixtapes that have at least one song
  scope :with_songs, includes(:songs).where('songs.id is not null')

  def name
    super || "Untitled Mix"
  end

  def creator
    "anonymous" # user.name
  end

  def duration
    songs.map(&:duration).reduce(:+) || 0
  end

  def voteable_by?(user)
    user && user.id != user_id
  end

  def warning
    case duration
    when 0..40*60
      nil
    when 40*60..45*60
      "Getting a bit long there! Our limit on mixes is 40 minutes. Though you won't be instantly disqualified, the added minutes better be damn worth it!"
    else
      "Holy moly this mix is long. You should probably cut it down a bit!"
    end
  end

  def filename
    "#{ name }.zip"
  end

  def cache_or_zip
    cache = File.stat(cache_path) rescue nil

    if !cache || cache.mtime < updated_at || cache.size < 100
      File.delete(cache_path) rescue nil
      prepare_zip
    end
  end

  def cache_path
    File.join(Settings.cache_path, "#{ id }.zip")
  end

  def prepare_zip
    Zip::ZipFile.open(cache_path, Zip::ZipFile::CREATE) do |zip|
      add_songs(zip)
    end
  end

  def add_songs(zip)
    songs.each do |song|
      song.tag_file
      zip.add(song.filename, song.file)
    end
  end

  def self.create_for(user)
    raise "No user supplied" unless user

    create do |mixtape|
      mixtape.user_id = user.id
    end
  end
end
