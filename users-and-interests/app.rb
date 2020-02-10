require 'sinatra'
require 'sinatra/reloader'
require 'yaml'

helpers do
  def count_users(yaml_hash)
    yaml_hash.keys.size
  end

  def count_interests(yaml_hash)
    yaml_hash.values.reduce(0) do |sum, values|
      sum + values[:interests].size
    end
  end.to_s
end

before do
  @data = YAML.load(File.read('users.yaml'))
  @users = @data.keys.map(&:to_s)
end

get '/' do

  erb :home
end

get '/:user' do
  @current_user = params[:user]

  erb :user
end