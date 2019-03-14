require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'
require 'securerandom'
enable :sessions
#TODO fix dynamic redirects
#arr.any
#request
configure do
    set :securedpaths, ["/profile/*","/newpost","/edit"]
    set :allowedfiles, [".jpg",".jpeg",".png"]
end

before do
    p request.path_info
    if settings.securedpaths.include?(request.path_info)
        if session[:username] != nil
            break
        else
            halt 401, 'Unauthorized Error 401'
        end
    end
end

get('/') do 
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    blogposts = db.execute("SELECT blogposts.Id, BlogTitle, BlogText, ImgPath, AuthorId, Username FROM blogposts INNER JOIN users on users.Id = blogposts.AuthorId ORDER BY blogposts.Id DESC")
    slim(:index, locals:{blogposts: blogposts})
end

get('/newuser') do
    slim(:register)
end

post('/login') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT Id, Username, Hash FROM users WHERE Username =?",params["username"])
    if result == []
        redirect('/denied')
    elsif checkpassword(params["password"],result[0]["Hash"]) == true
        session[:userid] = result[0]["Id"]
        session[:username] = params["username"]
        redirect("/profile/#{session[:userid]}")
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
    if db.execute("Select Username FROM users WHERE Username =?",params["username"]) != []
		params[:usernameerror] = true
        redirect('/newuser')
	else
		db.execute("INSERT INTO users(Username, Hash, Email) VALUES (?,?,?,?)",params["username"],hashedpassword,params["email"])    
	end
    session[:name] = params["name"]
    session[:username] = params["username"]
    redirect('/')
end

get('/profile/:id') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    blogposts = db.execute("SELECT blogposts.Id, BlogTitle, BlogText, ImgPath, AuthorId, Username FROM blogposts INNER JOIN users on users.Id = blogposts.AuthorId WHERE AuthorId = ? ORDER BY blogposts.Id DESC",params["id"])
    slim(:myprofile, locals:{blogposts: blogposts})
end

get('/newpost') do
    slim(:newpost)
end

post('/newpost') do
    db = SQLite3::Database.new('db/blog.db')
    imgname = params[:img][:filename]
    img = params[:img][:tempfile]
    if imgname.include?(".png") or imgname.include?(".jpg")
        newname = SecureRandom.hex(10) + "." + /(.*)\.(jpg|bmp|png|jpeg)$/.match(imgname)[2]
        File.open("public/img/#{newname}", 'wb') do |f|
            f.write(img.read)
        end
        db.execute("INSERT INTO blogposts(BlogTitle, BlogText, AuthorId, ImgPath) VALUES (?,?,?,?)",params["blog_title"],params["blog_text"],session[:userid],newname)
        redirect("/profile/#{session[:userid]}")
else
        "Please submit a picture"
    end
end

get('/editpost/:id') do 
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    result = db.execute("SELECT Id, BlogTitle, BlogText FROM blogposts WHERE Id = ?",params["id"])
    slim(:editpost, locals:{result: result})
end

post('/editpost/:id/update') do 
    db = SQLite3::Database.new('db/blog.db')
    db.execute("UPDATE blogposts SET BlogTitle = ?,BlogText = ? WHERE Id = ?",params["blog_title"],params["blog_text"],params["id"])
    redirect("/profile/#{session[:userid]}")
end

post('/editpost/:id/delete') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("DELETE FROM blogposts WHERE Id = (?)", params["id"])
    redirect("/profile/#{session[:userid]}")
end

get('/editprofile/:id') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    result = db.execute("SELECT Id, Username, Email FROM users WHERE Id = ?",params["id"])
    slim(:editprofile, locals:{result: result})
end

post('/editprofile/:id/update') do
    db = SQLite3::Database.new('db/blog.db')
    if params["password"] == ""
	    db.execute("UPDATE users set Username = ?, Email = ?, WHERE Id = ?",params["username"],params["email"],params["id"])    
    else
        hashedpassword = BCrypt::Password.create(params["password"])
        # if db.execute("Select username FROM users WHERE username =?",params["username"]) == params["username"] or db.execute("Select username FROM users WHERE username =?",params["username"]) != []
        # 	session[:usernameerror] = true
        #     redirect(back)
        # else
        # end
        # TODO fix duplicate username and email check
        db.execute("UPDATE users set Username = ?, Hash = ?, Email = ? WHERE Id = ?",params["username"],hashedpassword,params["email"],params["id"])    
    end
    session[:name] = params["name"]
    session[:username] = params["username"]
    redirect("/profile/#{session[:userid]}")
end