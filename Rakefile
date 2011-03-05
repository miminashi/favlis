require 'resque/tasks'
require 'lib/crawler'  # workerにclawlerのクラスを読み込ませるため

namespace :crawler do
  task :start do
    username = ENV['user']
    username = 'mrmayu' unless username
    Resque.enqueue(Favlis::Jobs::Crawl, username)
  end

  task :dequeue do
    'clawler:dequeue'
  end
end

namespace :worker do
=begin
  task :start do
    count = ENV['count']
    count = 1 if count == nil
    # COUNT=2 VVERBOSE=true QUEUE=default rake resque:workers
    #system "COUNT=#{count} VVERBOSE=true QUEUE=default rake resque:workers"
    Rake::Task['resque:workers'].invoke
  end
=end
end

namespace :tools do
  task :apply_model_callbacks do
    require 'config/mongo_settings'

    conditions = {:faved_users_count => nil}
    per_page = 1000

    puts "Tweet: #{Tweet.where(conditions).count} documents exists"
    while((t = Tweet.where(conditions).limit(per_page)).size > 0)
      t.each do |t|
        print "#{t.t_id}: #{t.faved_users.count}"
        t.save
        puts "=> #{t.faved_users_count}"
      end
      puts "Tweet: #{Tweet.where(conditions).count} documents exists"  
    end
  end

  task :insert_zero_to_user_last_crawl do
    require 'config/mongo_settings'

    conditions = {:last_crawl => nil}
    per_page = 1000

    puts "User: #{User.where(conditions).count} documents exists"
    while((u = User.where(conditions).limit(per_page)).size > 0)
      u.each do |u|
        print "#{u.screen_name}: #{u.last_crawl}"
        u.last_crawl = Time.at(0)
        u.save
        puts "=> #{u.last_crawl}"
      end
      puts "User: #{User.where(conditions).count} documents exists"  
    end
  end
end

