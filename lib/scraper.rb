#require 'pp'
require 'open-uri'
#require 'rubygems'
require 'nokogiri'

#$KCODE = 'u'

class Favlis
  class Utils
    class Scraper
      def initialize
        @statuses = []
        @users = []
        @state = nil
      end
      attr_reader :statuses
      attr_reader :users
      attr_reader :state

      def Scraper.scrape(user_name)
        s = Scraper.new
        s.scrape(user_name)
        return s
      end

      def scrape(user_name)
        url = 'http://twitter.com/' + user_name + '/favorites'

        begin
          file = open(url)
        rescue Timeout::Error, StandardError =>e
          p e
          "scrape#REQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUEREQUEUE"
          @state = :requeue
          return nil
        end

        unless file.base_uri.to_s == url
          p "scrape#EXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXITEXIT"
          @state = :exit
          return nil
        end

        doc = Nokogiri::HTML(file)
        statuses = doc.search(xpath_class_all('li', 'status'))
        #p statuses.size
        statuses.each do |t|
          status = {}

          status[:raw_html] = t.to_html
          status[:t_id] = t['id'].split('_')[1].to_i
          status[:from_user] = t.search(xpath_class('a', 'screen-name')).inner_text
          status[:profile_image_url] = t.search(xpath_class('a', 'profile-pic')).search(xpath_class('img', 'photo'))[0]['src']
          status[:text] = t.search(xpath_class('span', 'entry-content')).inner_html
          #p Time.parse(t.search(xpath_class('span', 'published'))[0]['data'].slice(7, 30))
          status[:created_at] = Time.parse(t.search(xpath_class('span', 'published'))[0]['data'])

          @statuses << status
          unless @users.map{|e| e[:screen_name]}.include?(status[:from_user])
            @users << {:screen_name => status[:from_user], :profile_image_url => status[:profile_image_url]}
          end
        end
        @state = :success
        return true
      end

      private
      def xpath_class(htmltag, classname)
        return '.' + xpath_class_all(htmltag, classname)
      end

      def xpath_class_all(htmltag, classname)
        return '//' + htmltag + '[contains(concat(" ",normalize-space(@class)," "), " ' + classname + ' ")]'
      end

    end
  end
end

# for simple test
if $0 == __FILE__
  scraped = Favlis::Utils::Scraper.scrape('http://twitter.com/mrmayu/favorites')
  scraped.statuses.each do |t|
    puts "#{t[:from_user]}: #{t[:text]}"
  end
  p scraped.users
end

