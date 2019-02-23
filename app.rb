require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'
enable :sessions

configure do
    set :securedpaths, ["/myprofile","/newpost","/edit"]
    set :allowedfiles, [".jpg",".jpeg",".png"]
end

before do
    if settings.securedpaths.include?(request.path_info)
        if session[:username] != nil
            break
        else
            halt 401, 'Unauthorized Error 401'
        end
    end
end

get('/') do 
    slim(:index)
end

get('/newuser') do
    slim(:register)
end

post('/login') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT Displayname, Username, Hash FROM users WHERE Username =?",params["username"])
    if result == []
        redirect('/denied')
    elsif checkpassword(params["password"],result[0]["Hash"]) == true
        session[:name] = result[0]["Displayname"]
        session[:username] = params["username"]
        redirect('/myprofile')
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
    redirect('/')
end

get('/myprofile') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    blogposts = db.execute("SELECT id, blog_title, blog_text, img_path FROM blogposts WHERE author_id = 2 ORDER BY id DESC")
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
        File.open("public/img/#{imgname}", 'wb') do |f|
            f.write(img.read)
        end
        db.execute("INSERT INTO blogposts(blog_title, blog_text, author_id, img_path) VALUES (?,?,?,?)",params["blog_title"],params["blog_text"],2,imgname)
        redirect('/myprofile')
    else
        "Please submit a picture"
    end
end

get('/edit/:id') do 
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    result = db.execute("SELECT id, blog_title, blog_text FROM blogposts WHERE id = ?",params["id"])
    slim(:editpost, locals:{result: result})
end

post('/edit/:id/update') do 
    db = SQLite3::Database.new('db/blog.db')
    db.execute("UPDATE blogposts SET blog_title = ?,blog_text = ? WHERE id = ?",params["blog_title"],params["blog_text"],params["id"])
    redirect('/myprofile')
end

post('/:id/delete') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("DELETE FROM blogposts WHERE id = (?)", params["id"])
    redirect('/myprofile')
end