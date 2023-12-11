# Event_Management App
Welcome to Event Managment App! This is a one-page version of a Event Management App. The app displays a list of events that the user can join or create new events. Each event typically includes a title, description, date, and location.

## Getting Started
To get started with the Event Manangment App, please follow the instructions below:

1. Extract the project from zip file.
2. Navigate to the project directory using your command prompt or terminal.
3. Run the command bundle install to install all necessary dependencies.

## Tech Stack
The tech stack used to build Sous Recipe Costing Calculator is:

* Ruby on Rails - a web application framework written in the Ruby programming language
* PostgreSQL - an open-source relational database management system


## Dependencies
The following dependencies are required to run Sous Recipe Costing Calculator:

* Ruby 3.1.2
* Rails 7.0.8
* PostgreSQL 15.0
* Node 20.8.1

## Installation Guide
>#### Install [RVM](https://rvm.io/rvm/install)
Install the right ruby version (currently 3.1.2):
```shell
  rvm install "ruby-3.1.2"
```

>#### Check your Ruby version
```shell
  ruby -v
```

The ouput should start with something like `ruby 3.1.2`

>#### Install Database (PostgreSQL) 15
```shell
  brew install postgresql@15
  brew services start postgresql
```

>#### Install [NVM](https://github.com/nvm-sh/nvm)
Install the right node version (currently 20.8.1):
```shell
  nvm install 20.8.1
```

>#### Check your Ruby version
```shell
  node -v
```

### Run this command to install all gems and dependencies

```
bundle install or bundle
```
## Database Setup:
```sh
rails db:create
rails db:migrate
```


## Running up the Server
```sh
bundle exec rails s
```

## Running Tests
```sh
bundle exec rspec
```

Once the server is running, you can access the application by navigating to http://localhost:3000 in your web browser.

## Functionality
With EVENTEMENT APP, you can perform the following actions:

1. Register User
2. Login User
3. Create a Event
4. Delete a Event
5. Join a Event


## Feedback
If you have any feedback or suggestions for improving EVENT MANAGEMENT APP, please feel free to reach out to me. I would love to hear from you!
