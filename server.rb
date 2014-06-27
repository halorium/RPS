# required gem includes
require 'sinatra'
require "sinatra/json"

# require file includes
require_relative 'lib/rps.rb'

enable :sessions

set :bind, '0.0.0.0' # Vagrant fix
set :port, 9494

get '/' do
  result = RPS::ValidateSession.run(params)
  if result[:success?]
    @errors = result[:errors]
    @player = result[:player]
    erb :home
  else
    erb :index
  end
end

post '/signup' do
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  if result[:success?]
    @errors.push('Please logout first before signing up')
    @player = result[:player]
    erb :home
  else
    result = RPS::SignUp.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success?]
      result = RPS::SignIn.run(params)
      @errors.push(result[:errors]).flatten

      if result[:success?]
        session[:rps_session_id] = result[:rps_session_id]
        @player = result[:player]
        erb :home
      else
        erb :login
      end
    else
      erb :login
    end
  end
end

post '/login' do
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    erb :home
  else
    erb :login
  end
end

post '/login' do
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    erb :home
  else
    result = RPS::SignIn.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success?]
      session[:session_id] = result[:session_id]
      @player = result[:player]
      erb :home
    else
      erb :login
    end
  end
end

get '/logout/:player_id' do
  result = RPS::DeleteSession.run(params)
  @errors = result[:errors]

  if result[:success?]
    session[:session_id] = nil
    erb :main
  else
    erb :main
  end
end

# TODO make api method
# get '/players/:player_id/matches' do
#   result = RPS::ValidateSession.run(params)
#   @errors = result[:errors]

#   if result[:success?]
#     @player  = result[:player]
#     @matches = @player.matches

#     erb :matches
#   else
#     erb :main
#   end
# end

# TODO make api method
# TODO '/players/:player_id/matches'
# post '/matches' do
#   result = RPS::ValidateSession.run(params)
#   @errors = result[:errors]

#   if result[:success?]
#     @player = result[:player]
#     result  = RPS::CreateMatch.run(params)
#     @errors.push(result[:errors]).flatten

#     if result[:success?]
#       @match = result[:match]

#       erb :match
#     else
#       erb :matches
#     end
#   else
#     erb :matches
#   end
# end

# TODO make api method (games with moves 'history')
# get '/matches/:match_id/games' do |match_id|
#   result = RPS::ValidateSession.run(params)
#   @errors = result[:errors]

#   if result[:success?]
#     @player = result[:player]
#     @match  = @player.get_match(match_id)
#     @games  = @match.games

#     erb :games
#   else
#     erb :home
#   end
# end

get '/matches/:match_id/games/:game_id' do |match_id,game_id|
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    @match  = @player.get_match(match_id)
    @game   = @match.get_game(game_id)

    erb :game
  else
    erb :games
  end
end

post '/matches/:match_id/games/:game_id' do |match_id,game_id|
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  if result[:success?]
# TODO refactor
# get player, match, game like method above then
# have a simple Play script that takes those and
# validates the play
    result = RPS::Play.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success]
      @player   = result[:player]
      @opponent = result[:opponent]
      @match    = result[:match]
      @game     = result[:game]
      @winner   = result[:winner]
    end

    erb :game
  else
    erb :login
  end
end

#-------- JSON API routes -----------

get '/api/players/:player_id/matches' do |player_id|
  result = RPS::ValidateSession.run(params)
  @errors = result[:errors]

  matches_array = []
  json_hash = {:matches => matches_array, :errors => @errors}

  if result[:success?]
    @player  = result[:player]
    @matches = @player.matches

    @matches.each do |match|
      matches_array.push( match.to_json_hash )
    end
  end

  JSON(json_hash)
end

# TODO make api method
# TODO '/players/:player_id/matches'
# post '/matches' do
#   result = RPS::ValidateSession.run(params)
#   @errors = result[:errors]

#   if result[:success?]
#     @player = result[:player]
#     result  = RPS::CreateMatch.run(params)
#     @errors.push(result[:errors]).flatten

#     if result[:success?]
#       @match = result[:match]

#       erb :match
#     else
#       erb :matches
#     end
#   else
#     erb :matches
#   end
# end

# TODO make api method (games with moves 'history')
# get '/matches/:match_id/games' do |match_id|
#   result = RPS::ValidateSession.run(params)
#   @errors = result[:errors]

#   if result[:success?]
#     @player = result[:player]
#     @match  = @player.get_match(match_id)
#     @games  = @match.games

#     erb :games
#   else
#     erb :home
#   end
# end



# post '/api/jokes/create' do
#   original_jokes_length = @@jokes.count
#   if params[:joke]['joke'].empty? || params[:joke]['answer'].empty?
#     response = {success: false, message: "you did fill things in"}
#   else
#     @@jokes.push(params[:joke])
#     if @@jokes.count == original_jokes_length + 1
#       response = {success: true, message: "You Added joke correctly"}
#     else
#       response = {success: false, message: "Something went wrong"}
#     end
#   end
#   json response
# end
