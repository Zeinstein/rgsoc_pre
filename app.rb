require 'rubygems'
require 'sinatra'
require 'erb'

require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'] || "sqlite://app.db")
Sequel::Model.strict_param_setting = false
require 'user'
require 'wish'
require 'comment'

require 'helpers'

enable :sessions

get "/" do
  @users = User.all
  erb :home
end

# RESTful konvenciók
# GET    /users => összes user
# GET    /users/new => új user form
# GET    /users/42 => 42 id-jű user oldala
# POST   /users => létrehoz usert
# GET    /users/42/edit => 42-es user szerkesztése
# PUT    /users/42 => módosítja a 42-es usert
# GET    /users/42/delete => 42-es user törlésének megerősítése
# DELETE /users/42 => törli a 42-es usert

get "/users/?" do
  require_user
  @users = User.all
  erb :"users/index"
end

get "/users/new" do
  unless logged_in?
    @user = User.new(params[:user] || {})
    erb :"users/new"
  else
    redirect "/users/#{current_user.id}"
  end
end

post "/users" do
  begin
    @user = User.new(params[:user] || {})
    @user.save
    session[:current_user_id] = @user.id
    session[:notice] = "Sikeres regisztráció, be is vagy már jelentkezve!"
    redirect "/users/#{@user.id}"
  rescue Sequel::ValidationFailed
    session[:error] = "Hiba az űrlapban"
    erb :"users/new"
  end
end

get "/users/:id" do
  require_user
  not_found unless @user = User[params[:id]]
  @wishes = Wish.filter(:user_id => params[:id])
  erb :"users/show"
end

get "/users/:id/edit" do
  require_user
  not_found unless @user = User[params[:id]]
  if @user == current_user
    erb :"users/edit"
  else
    session[:error] = "Csak a saját adataidat szerkesztheted!"
    redirect "/users/#{@user.id}"
  end
end

put "/users/:id" do
  require_user
  not_found unless @user = User[params[:id]]
  if @user == current_user
    begin
      @user.update_except(params[:user], :login)
      session[:notice] = "Sikeres módosítás!"
      redirect "/users/#{@user.id}"
    rescue Sequel::ValidationFailed
      session[:error] = "Hiba az űrlapban"
      erb :"users/edit"
    end
  else
    session[:error] = "Csak a saját adataidat szerkesztheted!"
    redirect "/users/#{@user.id}"
  end
end

get "/users/:id/delete" do
  require_user
  not_found unless @user = User[params[:id]]
  if @user == current_user
    erb :"users/delete"
  else
    session[:error] = "Mit gondolsz, csak úgy kitörölhetsz akárkit?"
    redirect "/users/#{@user.id}"
  end
end

delete "/users/:id" do
  require_user
  not_found unless @user = User[params[:id]]
  if @user == current_user
    @wishes = Wish.filter(:user_id => current_user.id)
    @wishes.each do |wish|
      @comments = Comment.filter(:wish_id => wish.id)
      @comments.each do |comment|
        comment.delete
      end
      wish.delete
    end
    @comments = Comment.filter(:user_id => current_user.id)
    @comments.each do |comment|
      comment.delete
    end
    @user.delete
    session[:current_user_id] = nil
    session[:notice] = "Sikeresen törölted magad!"
    redirect "/"
  else
    session[:error] = "Mit gondolsz, csak úgy kitörölhetsz akárkit?"
    redirect "/users/#{@user.id}"
  end
end

post "/login" do
  if user = User.authenticate(params[:user], params[:pass])
    session[:current_user_id] = user.id
    session[:notice] = "Sikeres bejelentkezés!"
    redirect session.delete(:back_url) || "/"
  else
    session[:error] = "Hibás felhasználónév vagy jelszó"
    redirect "/"
  end
end

get "/logout" do
  session[:current_user_id] = nil
  session[:notice] = "Sikeres kijelentkezés!"
  redirect "/"
end

get "/wishes/?" do
  require_user
  @wishes = Wish.filter(:user_id => current_user.id)
  erb :"wishes/index"
end

get "/wishes/new" do
  require_user
  @wish = Wish.new(params[:wish] || {})
  erb :"wishes/new"
end

post "/wishes" do
  require_user
  begin
    @wish = Wish.new(params[:wish] || {})
    @wish.user_id = current_user.id
    @wish.save
    session[:notice] = "Biztonságosan lejegyezted a kis kívánságodat..."
    redirect "/wishes/#{@wish.id}"
  rescue Sequel::ValidationFailed
    session[:error] = "Hiba az űrlapban"
    erb :"wishes/new"
  end
end

get "/wishes/:id" do
  require_user
  not_found unless @wish = Wish[params[:id]]
  error(403, "Nincs ehhez jogosultságod") unless logged_in?
  @comment = Comment.new(params[:comment] || {})
  @comments = Comment.filter(:wish_id => params[:id]).reverse_order(:created_at)
  erb :"wishes/show"
end

post "/comments" do
  require_user
  begin
    @comment = Comment.new(params[:comment] || {})
    @comment.save
    session[:notice] = "Biztonságosan lejegyezted a hozzászólásodat..."
    redirect "/wishes/#{@comment.wish_id}"
  rescue Sequel::ValidationFailed
    session[:error] = "Hiba az űrlapban"
    session.delete(:back_url) || "/"
  end
end

get "/wishes/:id/edit" do
  require_user
  not_found unless @wish = Wish[params[:id]]
  error(403, "Nincs ehhez jogosultságod") unless @wish.user_id == current_user.id
  erb :"wishes/edit"
end

put "/wishes/:id" do
  require_user
  not_found unless @wish = Wish[params[:id]]
  error(403, "Nincs ehhez jogosultságod") unless @wish.user_id == current_user.id
  begin
    @wish.update(params[:wish])
    session[:notice] = "Sikeres módosítás!"
    redirect "/wishes/#{@wish.id}"
  rescue Sequel::ValidationFailed
    session[:error] = "Hiba az űrlapban"
    erb :"wishes/edit"
  end
end

get "/wishes/:id/delete" do
  require_user
  not_found unless @wish = Wish[params[:id]]
  error(403, "Nincs ehhez jogosultságod") unless @wish.user_id == current_user.id
  erb :"wishes/delete"
end

delete "/wishes/:id" do
  require_user
  not_found unless @wish = Wish[params[:id]]
  error(403, "Nincs ehhez jogosultságod") unless @wish.user_id == current_user.id
  @comments = Comment.filter(:wish_id => wish.id)
  @comments.each do |comment|
    comment.delete
  end
  @wish.delete
  session[:notice] = "Sikeresen törölted a kis kívánságodat... de ne hidd, hogy így nem jönnek majd rá!"
  redirect "/wishes"
end


