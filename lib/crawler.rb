require 'resque'
require 'config/mongo_settings'
require 'config/crawler_settings'
require 'lib/scraper'

class Favlis
  class Jobs
    class Crawl
      @queue = :default

      def self.perform(username)
        Favlis::Utils::Crawler.crawl(username)
      end
    end
  end

  class Utils
    class Crawler
      def initialize(username)
        @username = username
      end

      def Crawler.crawl(username)
        crawler = Crawler.new(username)
        crawler.crawl
      end

      def crawl
        scraped = Favlis::Utils::Scraper.scrape(@username)
        if scraped.state == :requeue
          # 即再スケジュール
          self.enqueue(@username)
          r = false
        elsif scraped.state == :exit
          # 再スケジュールしない
          r = false
        elsif scraped.state == :success
          scraped.statuses.each do |s|
            self.insert_status(s)
          end
          scraped.users.each do |u|
            self.insert_user(u)
            self.enqueue(u[:screen_name])
          end
=begin
          user = User.first(:conditions => {:screen_name => @username})
          user.last_crawl = Time.now
          user.save
=end
          r = true
        end
        return r
      end

      def insert_status(status)
        tweet = Tweet.first(:conditions => {:t_id => status[:t_id]})
        if tweet
          _buff = tweet.faved_users.map{|u| u}
          unless tweet.faved_users.include?(@username)
            tweet.faved_users << @username
            p _buff
            p tweet.faved_users
            puts "exist #{status[:t_id]}: add #{@username}, #{_buff.size} -> #{tweet.faved_users.size}"
          else
            puts "exist #{status[:t_id]}: add none"
          end
        else
          tweet = Tweet.new do |t| 
            t.raw_html = status[:raw_html]
            t.t_id = status[:t_id]
            t.from_user = status[:from_user]
            t.profile_image_url = status[:profile_image_url]
            t.text = status[:text]
            t.created_at = status[:created_at]
          end
          tweet.faved_users << @username
          puts "new #{status[:t_id]}: add #{@username}"
        end
        tweet.save
      end

      def insert_user(u)
        screen_name = u[:screen_name]
        image_url = u[:profile_image_url]

        user = User.first(:conditions => {:screen_name => screen_name})
        unless user
          user = User.new(
            :screen_name => screen_name,
            :profile_image_url => image_url
          )
          user.save
        else
          if user.profile_image_url =! image_url
            user.profile_image_url = image_url
            user.save
          end
        end
        return user
      end

      def enqueue(username)
        if user = User.first(:conditions => {:screen_name => username})
          if (user.last_enqueue == nil) or (Time.now - user.last_enqueue > USER_ENQUEUE_INTERVAL)
            Resque.enqueue(Favlis::Jobs::Crawl, username)
            user.last_enqueue = Time.now
            user.save
          end
        end
      end
    end
  end
end

