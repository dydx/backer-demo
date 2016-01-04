# Backer-Demo

Utilizing [Backer](https://github.com/dydx/backer) and Backer's [In-Memory adapter](https://github.com/dydx/backer-memory), here is a working (if not a tad naive) implementation of Event Sourcing.

## Considerations
I am still actively researching the facets and methodologies of Event Sourcing and Command-Query Responsibility Segregation (CQRS). This is by no means a full-featured or highly efficient system to achieve separation of commands and queries, but it is a work in progress to help further my understanding of this great technology, and it works OK so far.

---------

## Overview
What I set out to create was a simple "twitter-style" webapp that stored command events in one repository, processed an aggregate into another, and then to queried it for display on the client.

I have chosen to log two sorts of events:

1. CreatedEvents
2. DeletedEvents

----------

## Creation Events
What I am choosing to call "CreatedEvents" are the system's interpretation of the client form being filled out and submitted.

Instead of immediately being stored in the database, this event is thrust into an in-memory events repository.

The "controller" action is simple:

>```ruby
>post '/new' do
>   # store a creation event
>   @event = settings.events.new
>   @event.name = "CreatedEvent"
>   @event.attributes = {:content => params[:content]}
>   settings.events.save(@event)
>
>   redirect '/'
>end
>```

Attributes are taken from Sinatra's `params` hash, which will be used later when processing the aggregate.

> ***TODO:*** I would like to make the syntax for my event models better, perhaps allowing something similar to: `@event.save` when storing the event, instead of having to call the `save` method from the Repo

## Deletion Events
Deletion events are very similar to creation events, except we are operating on objects in the system that already exist and are modifying their state.

The real difference here is that we are not changing the state of the object in the event repository but instead are affecting its state in the aggregate.

The event repository is immutable, events cannot be deleted or modified from the log itself-- attributes on the objects that the events represent are instead changed over time (think of your bank ledger over a given month-- at every point you can see what transactions were used to calculate your overall balance).

The controller action for handling deletion events is fairly simple, though I do intend to switch from a `GET` to a `POST` request for security's sake:

>```ruby
>get '/delete/:id' do
>   id = params[:id].to_i
>
>   # store a deletion event
>   @event = settings.events.new
>   @event.name = "DeletedEvent"
>   @event.attributes = {:id => id, :deleted => true}
>   settings.events.save(@event)
>
>   redirect '/'
>end
>```

Here we are creating another event with the name `DeletedEvent` and storing updated attributes for the aggregate.

------------

## Aggregate
The aggregate is, ideally, calculated at set intervals of time or transactions, and its process is not run in the foreground. In my implementation with Sinatra and Backer, I have chosen to calculate the aggregate when the client requests `'/'`. A global counter is incremented for ever seen event from the events repository, and checks are made on each request to make sure to not re-run commands against the aggregate.

The controller action for this a bit long, but also fairly straight forward:

>```ruby
>get '/' do
>  # get all of the events on record
>  @events = settings.events.all
>  # iterate through them
>  @events.each do |event|
>    # if we havent yet processed this event
>    if event.id > settings.latest
>      # check for the event name
>      case event.name
>      when "CreatedEvent"
>        # create a new model
>        @tweet = settings.tweets.new
>        @tweet.content = event.attributes[:content]
>        settings.tweets.save(@tweet)
>      when "DeletedEvent"
>        # change the attributes of the model
>        @tweet = settings.tweets.find_by_id(event.attributes[:id])
>        @tweet.deleted = true
>        settings.tweets.save(@tweet)
>      else
>        # unknown event
>        puts event
>      end
>      # update the latest seen event
>      settings.latest = event.id
>    end
>  end
>
>  # pull from the newly refreshed aggregate
>  @tweets = settings.tweets.all
>  erb :index, locals: {tweets: @tweets}
>end
>```

I've tried to write comments within the action to make it more clear what steps are involved with calculating the aggregate from contents of the events repository

There is a lot of work I'd like to do with making this part of the application (arguably the key component of it) a bit ... nicer.

I have toyed with the idea of using a message queue or a job queue for this interaction, though I am still exploring different ways to keep the events repository and the aggregate separated as well as have data be piped from one into the other at set intervals.

## A little visual demo
![Screencast](http://g.recordit.co/00jpGRNbgz.gif)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dydx/backer-demo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


