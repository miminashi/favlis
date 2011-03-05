require 'mongoid'

#MONGO_SERVER = '172.16.0.65'
MONGO_SERVER = '127.0.0.1'

Mongoid.configure do |conf|
  conf.master = Mongo::Connection.new(MONGO_SERVER, 27017).db('favlis')
end

class Tweet
  include Mongoid::Document
  field :raw_html
  field :t_id
  field :from_user
  field :profile_image_url
  field :text
  field :created_at
  field :faved_users, :type => Array, :default => []
  field :faved_users_count, :type => Integer
  field :retweeted_users, :type => Array, :default => []
  field :retweeted_users_count, :type => Integer
  #key :t_id
  before_save :update_all_counts

  protected
  def update_all_counts
    self.faved_users = [] unless self.faved_users
    self.faved_users_count = self.faved_users.size

    self.retweeted_users = [] unless self.retweeted_users
    self.retweeted_users_count = self.retweeted_users.size
  end
end

class User
  include Mongoid::Document
  field :screen_name
  field :profile_image_url
  field :last_crawl, :type => Time, :default => Time.at(0)
end

