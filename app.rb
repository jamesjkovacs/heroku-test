require 'sinatra/base'
require 'sinatra'
require 'mongo'
require 'bson'
require './mongoutils'
require 'bcrypt'

class ComingSoonApp < Sinatra::Base
  include MongoUtils
  MongoUtils.mongodb_config(ENV['RACK_ENV'])
  $mongo = MongoUtils.mongodb_connect(ENV['RACK_ENV'])
  
  set :public_folder, File.dirname(__FILE__) + '/static'
  enable :sessions
  enable :logging

  get '/' do
    erb :index
  end
  
  post '/notify' do
    collection = $mongo.collection("to_be_contacted")
    collection.update({"email" => params[:email]}, {"$set" => {"entry_date" => Time.now.utc }}, {:upsert => true})
    redirect to('/thankyou')
  end
  
  
  get '/thankyou' do
    erb :thankyou
  end
  
  post "/login" do
    collection = $mongo.collection("users")
    user = collection.find_one({"username" => params[:username]})
    if not user == nil 
      password_hash = BCrypt::Engine.hash_secret(params[:password], user["password_salt"])
      if password_hash == user["password_hash"] then
        session[:user] = user["_id"].to_s
        redirect to('/contacts')
      end
    end
    redirect to('/login')
  end
  
  get "/login" do
    if session[:user] == nil
      erb :login
    else
      redirect to('/contacts')
    end
  end
  
  get "/logout" do 
    session[:user] = nil
    redirect to('/')
  end
  
  
  get '/contacts' do
    if session[:user] == nil
      redirect to('/login')
    end
    
    collection = $mongo.collection("to_be_contacted")
    @emails = collection.find
    erb :contacts
  end

  get '/contacts/export' do
    if session[:user] == nil
      redirect to('/login')
    end
    
    headers "Content-Disposition" => "attachment;filename=contacts.csv",
      "Content-Type" => "application/octet-stream"
    result = ""
    collection = $mongo.collection("to_be_contacted")
    contacts = collection.find
    contacts.each do |contact|
      result << "#{contact['entry_date'].strftime("%d %b %y")}, #{contact['email']}\n"
    end
    
    return result
  end
end