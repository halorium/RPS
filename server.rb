# required gem includes
require 'sinatra'
require "sinatra/json"

# require file includes
require_relative 'lib/rps.rb'

enable :sessions

set :bind, '0.0.0.0' # Vagrant fix
set :port, 9494

get '/' do
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    redirect to "player/#{@player.player_id}"
  else
    erb :index
  end
end

post '/signup' do
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    redirect to "player/#{@player.player_id}"
  else
    result = RPS::SignUp.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success?]
      result = RPS::SignIn.run(params)
      @errors.push(result[:errors]).flatten

      if result[:success?]
        session[:rps_session_id] = result[:rps_session_id]
        @player = result[:player]
        redirect to "player/#{@player.player_id}"
      else
        erb :index
      end
    else
      erb :index
    end
  end
end

post '/login' do
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    redirect to "player/#{@player.player_id}"
  else
    result = RPS::SignIn.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success?]
      session[:rps_session_id] = result[:rps_session_id]
      @player = result[:player]

      redirect to "player/#{@player.player_id}"
    else
      erb :index
    end
  end
end

post '/logout' do
  result = RPS::DeleteSession.run(session)
  @errors = result[:errors]

  session.clear
  erb :index
end

get '/player/:player_id' do |player_id|
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]

  if result[:success?]
    @player = result[:player]
    erb :home
  else
    erb :index
  end
end

# get '/player/:player_id/matches/:match_id' do |player_id,match_id|
#   result = RPS::ValidateSession.run(session)
#   @errors = result[:errors]

#   if result[:success?]
#     @player = result[:player]
#     @match  = @player.get_match(match_id)
#     @game   = @match.get_current_game

#     erb :game
#   else
#     erb :home
#   end
# end

get '/player/:player_id/matches/:match_id/games/:game_id' do |player_id,match_id,game_id|
  result = RPS::ValidateSession.run(session)
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

post '/player/:player_id/matches/:match_id/games/:game_id' do |player_id,match_id,game_id|
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]

  if result[:success?]
# TODO refactor
# get player, match, game like method above then
# have a simple Play script that takes those and
# validates the play
    result = RPS::Play.run(params)
    @errors.push(result[:errors]).flatten

    if result[:success]
      unless winner
        create new_game
      end

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
  result = RPS::ValidateSession.run(session)
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

post '/players/:username/matches' do |username|
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]
  json_hash = {:errors => @errors}

  if result[:success?]
    @player = result[:player]

    result  = RPS::CreateMatch.run(params, @player)
    @errors.push(result[:errors]).flatten

    if result[:success?]
      @match = result[:match]

      json_hash[:match] = @match.to_json_hash
    end
  end

  JSON(json_hash)
end

get '/matches/:match_id/history' do |match_id|
  result = RPS::ValidateSession.run(session)
  @errors = result[:errors]
  json_hash = {:errors => @errors}

  if result[:success?]
    @player = result[:player]
    @match  = @player.get_match(match_id)

    if @match
      result = RPS::MatchHistory(params, @match)
      @errors.push(result[:errors]).flatten

      if result[:success?]
        json_hash[:success] = true
        json_hash[:history] = result[:history]
      end
    end
  end

  JSON(json_hash)
end
