#require 'open-uri'
require 'resque'
require 'config/mongo_settings'
require 'config/crawler_settings'
require 'lib/scraper'

require 'pp'

=begin
EventMachine.run {
  multi = EventMachine::MultiRequest.new

  uri = 'http://twitter.com/favorites/' + id.to_s + '.rss'
  multi.add(EventMachine::HttpRequest.new(uri).get)
 
  #multi.add(EventMachine::HttpRequest.new('http://twitter.com/favorites/28524511.rss').get)
  #multi.add(EventMachine::HttpRequest.new('http://twitter.com/favorites/112902689.rss').get)

  multi.callback {
    multi.responses[:succeeded].each do |ele|
      uri = ele.uri.to_s
      rss = RSS::Parser.parse(ele.response, false)
      begin
        link = rss.channel.link
      rescue
        pp rss
      end
      p uri
      #rss.items.each do |item|
      #  pp item
      #end
    end
    pp multi.responses[:failed]

    EventMachine.stop
  }
}
=end

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
        #p 'crawl'
        scraped = Favlis::Utils::Scraper.scrape(@username)
        #p scraped.state
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
          user = User.first(:conditions => {:screen_name => @username})
          user.last_crawl = Time.now
          user.save
          r = true
          puts "#{@username}: #{scraped.users.map{|u| u[:screen_name]}.inspect}"
        end
        return r
      end

      def insert_status(status)
        #faved_user = FavedUser.new(:screen_name => @username)
        tweet = Tweet.first(:conditions => {:t_id => status[:t_id]})
        if tweet
          tweet.faved_users << @username unless tweet.faved_users.include?(@username)
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
          if Time.now - user.last_crawl > CRAWL_USER_INTERVAL
            Resque.enqueue(Favlis::Jobs::Crawl, username)
          end
        end
      end
    end
  end
end

