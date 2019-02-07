require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

configure do
    set :securedpaths, ["/welcome","/tjena"]
end

# before do
#     p "Tjena"
#     p request.path_info
#     if settings.securedpaths.include?(request.path_info)
#         if session[:username] != nil
#             redirect(request.path_info)
#         else
#             halt 401, 'Error 401'
#         end
#     else
#         redirect(request.path_info)
#     end
# end

get('/') do 
    slim(:index)
end

get('/newuser') do
    slim(:register)
end

#if aklsjdklasd
    #before do


post('/login') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT Displayname, Username, Hash FROM users WHERE Username =?",params["username"])
    if result == []
        redirect('/denied')
    elsif checkpassword(params["password"],result[0]["Hash"]) == true
        session[:name] = result[0]["Displayname"]
        session[:username] = params["username"]
        redirect('/welcome')
    else
        redirect('/denied')
    end
end

def checkpassword(pw,dbpw)
	if BCrypt::Password.new(dbpw) == pw
		return true
    else
        return false
    end
end

get('/welcome') do
        slim(:welcome)
end

get('/denied') do
    slim(:denied)
end

post('/logout') do
    session[:username] = nil
    session[:password] = nil
    session.destroy
    redirect('/')
end

post('/register') do
    db = SQLite3::Database.new("db/blog.db")
    hashedpassword = BCrypt::Password.create(params["password"])
    if db.execute("Select username FROM users WHERE username =?",params["username"]) != []
		session[:usernameerror] = true
        redirect('/newuser')
	else
		db.execute("INSERT INTO users(Username, Hash, Email, Displayname, Accounttype) VALUES (?,?,?,?,?)",params["username"],hashedpassword,params["email"],params["name"],"admin")    
	end
    session[:name] = params["name"]
    session[:username] = params["username"]
    redirect('/welcome')
end