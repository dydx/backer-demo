require 'sinatra'
require 'tilt/erb'

require 'backer'
require 'backer/memory'

require_relative './lib/loader.rb'

configure do
  Backer::Repo.register(:tweet, TweetMemoryRepository.new)
  Backer::Repo.register(:event, EventMemoryRepository.new)

  set :tweets, Backer::Repo.for(:tweet)
  set :events, Backer::Repo.for(:event)
  set :latest, 0

  set :server, %w[thin]
end

get '/' do
  # get all of the events on record
  @events = settings.events.all
  # iterate through them
  @events.each do |event|
    # if we havent yet processed this event
    if event.id > settings.latest
      # check for the event name
      case event.name
      when "CreatedEvent"
        # create a new model
        @tweet = settings.tweets.new
        @tweet.content = event.attributes[:content]
        settings.tweets.save(@tweet)
      when "DeletedEvent"
        # change the attributes of the model
        @tweet = settings.tweets.find_by_id(event.attributes[:id])
        @tweet.deleted = true
        settings.tweets.save(@tweet)
      else
        # unknown event
        puts event
      end
      # update the latest seen event
      settings.latest = event.id
    end
  end

  # pull from the newly refreshed aggregate
  @tweets = settings.tweets.all
  erb :index, locals: {tweets: @tweets}
end

get '/delete/:id' do
  id = params[:id].to_i

  # store a deletion event
  @event = settings.events.new
  @event.name = "DeletedEvent"
  @event.attributes = {:id => id, :deleted => true}
  settings.events.save(@event)

  redirect '/'
end

post '/new' do
  # store a creation event
  @event = settings.events.new
  @event.name = "CreatedEvent"
  @event.attributes = {:content => params[:content]}
  settings.events.save(@event)

  redirect '/'
end
