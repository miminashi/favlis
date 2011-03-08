require 'sinatra/base'
require 'erb'
require 'lib/model'

class Favlis
  class App < Sinatra::Base
    configure do
      enable :dump_errors
    end

    helpers do
      def render_sidebar(params=nil)
        erb :sidebar_search
      end

      def err_404(message=nil)
        status 404
        erb :err_404, :layout => :layout_nosidebar
      end

      def profile_image_url(username)
        return User.first(:conditions => {:screen_name => username}).profile_image_url
      end
    end

    get '/' do
      @statuses = Tweet.order_by([[:faved_users_count, :desc], [:t_id, :desc]]).limit(3)
=begin
      @statuses.each do |s|
        p s.faved_users
      end
=end
      erb :index, :layout => false
    end

    get '/search/:keyword' do
      #@statuses = Tweet.
      erb :search
    end

    get '/search' do
      case params[:type]
      when 'keyword'
        redirect '/'
      when 'tag'
        redirect '/'
      when 'user'
        redirect "/user/#{params[:query]}"
      else
        err_404
      end
    end

    get '/user/:user/:page' do
      if params[:page].to_i < 1
        err_404
      else
        @statuses = Tweet.paginate(:conditions => {:from_user => params[:user]}, :page => params[:page], :per_page => 15)
        erb :user
      end
    end

    get '/user/:user' do
      @statuses = Tweet.paginate(:conditions => {:from_user => params[:user]}, :page => 1, :per_page => 15)
      erb :user
    end

    get '/status' do
      @tweets_count = Tweet.count
      @users_count = User.count
      erb :status
    end
  end
end

