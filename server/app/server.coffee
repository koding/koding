class Server
  json404     = '{"errno":404}'
  index_html  = ''

  constructor : (port=3000, host="koding.com") ->
    
    @port = port
    @host = "koding.com"
        
    app   = express.createServer()
    app.use express.bodyParser()
    # app.use express.methodOverride()
    app.use express.cookieParser()
    app.use express.session {"secret":"foo"}
    app.use gzippo.staticGzip "#{process.argv[2]}/website/"
    app.use (req, res, next)->
      res.removeHeader("X-Powered-By")
      next()
    # app.use express.static "#{process.argv[2]}/website/"
    #solder.expressRoute server
    #@everyone = nowjs.initialize app
    #exposeApi @everyone
    
#     bongo.listen app, io : {
#       # 'match origin protocol': yes
#       transports: [
# #       'websocket'
# #       we're taking the websocket transport away from socket.io
#         'xhr-polling'
#         'xhr-multipart'
#         'jsonp-polling'
#       ]
#     }#.listen 5000
    
    #nowjs.server.set 'log level', 1

    @req
    @res
    @sessions = {}
    @users = {}
    @guests = {}

    # @initializeSessions()

    # these are for unloading users from memory
    @staleUsers = []

    # workers = []
    # workers.push "worker"+x for x in [0..4]
    # honcho = (new manager()).addWorkers(workers)

    #
    #app.get "/:target/:operation/:singleParam?", (req,res)=>
    #  @setCurrent req, res
    #  target = req.params.target
    #  op = req.params.operation
    #
    #
    #  oldSetCookie = res.cookie
    #  res.setCookie = ->
    #    oldSetCookie.apply res, slice.call arguments
    #
    #
    #
    ###
      if user isnt false and req.params.operation is "status" and req.params.jobid?
        log "getting the job:"+req.params.jobid
        res.send user.managers[0].getJob req.params.jobid
      else if req.params.operation is "add"
        res.send user.managers[0].addJobToQueue req.params.jobid, req.query

    app.get "/jobs/:operation",(req,res)=>
      @setCurrent req, res
      user = @getUser req, res
      if user isnt false and req.params.operation is "listAll"
        res.send user.managers[0].listJobs()
      else res.send null
    app.get "/api/:operation?", (req,res) =>
      log "-----------------------------------------"
      @req = req
      @res = res
      res.header "Server","Kodejs"
      global.user = user = @getUser()
      if req.params.operation isnt "login"
        res.send user.managers[0].addJobToQueue req.params.operation, req.query

      res.send "got your command, nothing to say back (change me to a proper api return.)"
    ###
    # app.get "/js", (req, res)->
    # app.get "/css/kd.css", (req, res)->
    #   fs.readFile "./website/css/kd.css",(err,data)->
    #     res.header "content-type":"application/gzip"
    #     res.send data

    # app.get '/activity.feed', (req, res)->
    #   options = req.query or {}
    #   for own key, option of options
    #     switch key
    #       when 'limit','skip'
    #         options[key] = +option
    #       when 'hint', 'sort'
    #         for own sortKey, sortOrder of option
    #           options[key][sortKey] = +sortOrder
    #   CActivity.someData {snapshot:$exists:1}, {snapshot:1}, options, (err, cursor)->
    #     if err
    #       console.log 'error:', err
    #     cursor.toArray (err, arr)->
    #       if err
    #         console.log 'error:', err
    #       # res.header 200, 'text/plain'
    #       res.send 'feed:'+(item.snapshot for item in arr).join '\n'
    
    app.get '/auth', (req, res)->
      crypto = require 'crypto'
      channel = req.query?.channel
      return res.send "-1" unless channel
      clientId = req.cookies.clientid
      JSession.one {clientId}, (err, session)->
        [priv, type, pubName] = channel.split '-'
        {username} = session
        cipher = crypto.createCipher('aes-256-cbc', '2bB0y1u~64=d|CS')
        cipher.update(
          ''+pubName+req.cookies.clientid+Date.now()+Math.random()
        )
        privName = ['secret', type, cipher.final('hex')+".#{username}"].join '-'
        privName += '.private'
        koding.mq.emit('race-condition','race-condition','koding')
        koding.mq.emit(channel, 'join', privName)
        return res.send privName


    app.get '/images/uploads/:filename', (req, res)->
      {filename} = req.params
      Resource.get filename, (err, gs, data, responseCode)->
        if err
          res.send "<h1>#{responseCode}!</h1><p>#{err.message}</p>", responseCode
        else
          res.header 'Content-type', gs.contentType
          if gs.metadata.uploadedBy
            res.header 'X-Uploaded-by', gs.metadata.uploadedBy
          res.send data

    app.get "/", (req, res)->
      if frag = req.query._escaped_fragment_?
        res.send 'this is crawlable content '
      else
        # log.info "serving index.html"
        res.header 'Content-type', 'text/html'
        fs.readFile "#{process.argv[2]}/website_nonstatic/index.html", (err, data) ->
          throw err if err
          res.send data
    
    # app.post '/channel/auth', (req, res)=>
    #   {socket_id, channel_name} = req.body
    #   res.send bongo.mq.auth socket_id, channel_name
    # 
    # app.get "/:taskName.jsonh", (req, res)=>
    #   authKey   = req.cookies.kdkey
    #   taskName  = req.params.taskName
    #   params    = req.query
    #   @fetchAccount authKey, (account, user)=>
    #     account.fetchManager (manager)=>
    #       unless manager then return callback new Error 'no manager'
    #       manager.addJobToQueue taskName, params, {
    #         authKey
    #         callback: (collection)=>
    #           if collection.length
    #             collection = JSONH.stringify(
    #               @filterCollection collection, account, params
    #             )
    #           json = collection or json404
    #           callback = req.query.callback or ''
    #           res.send "#{callback}(#{json})"
    #       }
        #res.render __dirname+"/../../client/index.html"

    # app.get '/', (req,res) =>
    #   user = @getUser()
    #   if      req.param "stopWorker"    then honcho.stopWorker    req.param "stopWorker"
    #   else if req.param "startWorker"   then honcho.startWorker   req.param "startWorker"
    #   else if req.param "addWorker"     then honcho.addWorkers    req.param "addWorker"
    #   else if req.param "removeWorker"  then honcho.removeWorker  req.param "removeWorker"
    #   else if req.param "listJobs"      then res.send honcho.listJobs()
    #   else if req.param "listWorkers"   then res.send honcho.getWorkers()
    #   else if req.param "addJob"        then res.send honcho.addJobToQueue req.query
    #   else    res.send "ready."
    #   res.send "ready"
    #   res.send honcho.getWorkers()
    
    # app.get '/kite/:what?',(req,res)->
    #   
    #   data = JSON.parse req.query.data
    #   res.send data.name      
    #   # log data
    #   log req.params.what
    #   switch req.params.what
    #     when "connect"
    #       KiteController.registerKite
    #         connType : "http"
    #         kite     : data.kite

    # app.get '/logout/:username?', (req,res) =>
    #   username = req.query.username ? req.params.username
    #   # TODO: implement log out like this:
    #   @getUser(username).logout()
    #   @setCurrent req, res
    #   res.send success: yes
    #   
    # app.get '/download/:fileName', (req, res, next) =>
    #   authKey   = req.cookies.kdkey
    #   fileName  = req.param('fileName')
    #   @fetchAccount authKey, (account, user)->
    #     fullPath = account.getTempPath(fileName)
    #     Path.exists fullPath, (exists) ->
    #       if exists
    #         res.download fullPath
    #       else
    #         next()

    app.get '*', (req,res)->
      res.header 'Location', '/#!'+req.url
      res.send 302

    app.listen port
    # log "http://localhost:#{port} started"
    spawn.apply null, ["say",["ready"]]
    

  # initializeSessions:=>
  #   Session.find timestamp: $gte: Date.now() - @getSessionMaxLifetime(), (err, cursor) =>
  #     freshUsers = []
  #     for session in cursor
  #       @sessions[session.authKey] = session
  #       {username, guestId} = session
  #       if username? and not @users[username]?
  #         if username not in freshUsers
  #           freshUsers.push username
  #       else if guestId? and not @guests[guestId]?
  #         @guests[guestId] = new Guest {guestId}
  # 
  #     @startupUsers freshUsers
  # 
  #   @sessionCronInterval = setInterval @runSessionCron, @getSessionCronDelay()

  # throttleBatch:(fullBatch, fn, params...)=>
  #   len = fullBatch.length
  #   if len
  #     max = @getMaxBatchSize()
  # 
  #     batchSize = if len < max then len else max
  #     batch = splice.call fullBatch, 0, batchSize
  # 
  #     for item in batch
  #       fn? item, params...
  # 
  # startupUsers:(usernames)=>
  #   setInterval =>
  #     @throttleBatch usernames, (username)=>
  #       User.findOne {username}, (err, user)=>
  #         @users[user.get "username"] = user
  #   , @getThrottleTempo()
  # 
  # runSessionCron:=>
  #   @throttleBatch @staleUsers, (username)->
  #     Session.remove {username}
  # 
  # getChannel: ->
  # 
  # getThrottleTempo:->
  #   # this function could be very sophisticated if it wanted to be.
  #   100
  # 
  # getMaxBatchSize:->
  #   500
  # 
  # getSessionCronDelay:->
  #   1000*15
  # 
  # getSessionMaxLifetime:->
  #   1000*60*60*24*7 # is 1 week

  # closeSession:(user) ->
  #   if @users[user.username]?
  #     delete @users[user.username]
  #     (new Auth).clearCookie()
  #     @req.session.destroy()

  # handle:(req,res) ->
  #   res.send null
  # 
  # handleJobs:(req,res) ->
  #   target = req.params.target
  #   user = @getUser()
  #   switch op = req.params.operation
  # 
  #     when 'add'
  #       target is 'job' and res.send user.managers[0].addJobToQueue req.params.singleParam, req.query
  # 
  #     when 'status'
  #       jobId = req.query.id ? req.params.singleParam
  #       if target is 'job'
  #         if job = user.managers[0].getJob jobId
  #           res.send job
  #         else
  #           res.send success:false, error: new Error "Job ID #{jobId} was not found!"
  # 
  #     when 'all'
  #       target is 'jobs' and res.send user.managers[0].listJobs()
  # 
  #     else @handle(req,res);

  setCurrent:(req,res) ->
    @req = req
    @res = res

  # makeGuest:(authKey, callback)->
  #   Guest.___count or= 0
  #   Guest.___count += 1
  # 
  #   guest = new Guest
  # 
  #   @makeSession guest, authKey, ->
  #     callback guest
  # 
  # fetchUser:(authKey, callback)->
  #   if authKey = authKey ? @res?.cookies?.kdKey
  #     if session = @sessions[authKey]
  #       if user = @users[session.username]
  #         return callback user
  #       else if guest = @guests[session.guestId]
  #         callback guest
  #       else
  #         User.findOne username: session.username, (err, user) =>
  #           unless user
  #             @makeGuest authKey, callback
  #           else
  #             callback user
  # 
  #     else
  #       @makeGuest authKey, callback

  # fetchAccount:(authKey, callback)->
  #   @fetchUser authKey, (user)=>
  #     user.fetchActiveAccount (account)=>
  #       callback account, user
  # 
  # filterCollection:(collection, account, params)->
  #   filter = outputFilters['default']
  #   output = []
  #   for item in collection
  #     if item
  #       output.push filter item, account, params
  #   output
  # 
  # doLogin:(cred, authKey, callback)=>
  #   @fetchUser authKey, (guest)=>
  #     unless guest.isLoggedIn()
  #       User.findOne cred, (err, user) =>
  #         if err
  #           callback success: no, error: err
  #         else if user
  #           newAuthKey = u.makeAuthKey user.get 'username'
  #         # TODO: authenticate
  #         if user
  #           if user.get().status is 'banned'
  #             callback success: no, error: new Error('This account is banned!'), declinedCredentials: cred
  #           else
  #             # TODO: Fix @clearGuestSession. raise bug when new user register
  #             @clearGuestSession guest
  # 
  #             @makeSession user, newAuthKey, =>
  #               callback success: yes, authKey: newAuthKey, user
  # 
  #         else callback success: no, error: new Error('Login failed!'), declinedCredentials: cred
  #     else callback success: no, error: new Error 'You are already logged in!'
  # 
  # doLogout:(authKey,callback)=>
  #   @fetchUser authKey, (user)=>
  #     if user.isLoggedIn()
  #       username = user.get 'username'
  #       user = @users[username]
  #       #console.log 'Logout user', username, @users[username]
  #       delete @users[username]
  #       @staleUsers.push username
  #       callback success: yes, user: user.get()#user.get() - fixes circular structure error
  #     else callback success: no, error: new Error 'You are not logged in!'
  # 
  # 
  # makeSession:(user, authKey, callback)=>
  #   session = new Session
  #   session.authKey = authKey
  #   session.timestamp = Date.now()
  # 
  #   if user.isLoggedIn()
  #     @users[user.get 'username'] = user
  #     session.username = user.get 'username'
  # 
  #   else if guestId = user.guestId
  #     @guests[guestId] = user
  #     session.guestId = guestId
  # 
  #   session.save()
  #   @sessions[authKey] = session
  # 
  #   callback authKey
  # 
  # clearGuestSession:(guest)->
  #   {guestId} = guest
  #   Session.remove {guestId}, (err)-> console.log 'clearGuestSession err is', err if err
    # console.log '------before delete', guestId, @guests[guestId], @guests
    # @guests[guestId] = null if @guests?[guestId]?
    # delete @guests[guestId] if @guests[guestId]
    
    
  ###
  canLogin:(username,password)->
    if username is "devrim" and password is "1234" then true
    else if username is "sinan" and password is "1234" then true
    else if username is "aleksey" and password is "1234" then true
    else false
  ###
  # checkLogin:=>
  #    @req.params.operation is 'login' and @req.query.username isnt null and @req.query.password isnt null
  # 
  # 
  #  refreshUser:(username, callback)->
  #    User.findOne {username}, (err, user)=>
  #      unless err
  #        @users[username] = user
  #        return callback success: yes
  #      else
  #        return callback success: no, err: err
  # 
  #  getUser: (authKey)->
  #   {username, guestId} = @sessions[authKey]
  #   @users?[username]# ? @guests[guestId]
  # 
  #  getTimeoutIdStackoverflow: (authKey)->
  #    @sessions[authKey].timeoutIdStackoverflow
  # 
  #  setTimeoutIdStackoverflow: (authKey, value)->
  #    @sessions[authKey].timeoutIdStackoverflow = value
  # 
  #  getDropboxInstance: (authKey, callback)->
  #    if dropbox = @sessions[authKey]?.dropbox
  #      return callback {success: yes, dropbox}
  #    else
  #      @fetchAccount authKey, (account, user)=>
  #        account.fetchMounts (mounts)=>
  #          for mount in mounts
  #            item = mount.getFilteredDoc()
  #            if item.type is 'Dropbox'
  #              itemDropbox = item
  #              break
  #          throw new Error "cant found dropbox mount" unless itemDropbox?
  #          configDropbox = config.foreignProviders?.dropbox
  #          {consumerKey, consumerSecret} = configDropbox
  #          {accessToken, accessSecret}   = itemDropbox
  #          dropbox = new DropboxClient consumerKey, consumerSecret, accessToken, accessSecret
  #          unless @sessions[authKey]? then throw new Error 'authKey not in @sessions ' + authKey
  #          @sessions[authKey].dropbox = dropbox
  #          return callback {success: yes, dropbox}

###
(->
  getOrAddUser = (username)->
    unless username?
      throw new Error 'No username provided'
    if @users[username]?
      log username+" has already an active session, continuing on..."
      @users[username]
    else
      user = @users[username] = User.factory username, (user)->
        flog 'private Server::getOrAddUser', user, '\n\n\n'
      user
  Server::getUser = ->
    username = (new Auth).decryptCookie()
    user = @users[username] or User.factory 'guest'
    flog "Server::getUser (#{username} from cookie)", user
    user

    if @checkLogin()
      console.log "login api call is made"
      if @canLogin @req.query.username, @req.query.password
        console.log "login successful"
        getOrAddUser.call @, @req.query.username
      else
        console.log "login failed"
        ret =
          status: "error"
          desc: "you are not logged in"
        @res.send ret
        false
    else
      username = (new Auth).decryptCookie()
      log 'username decrypted from cookie: '+username
      unless username? then throw new Error 'Not authorized'
      console.log "decrypted username is "+username
      if username
        getOrAddUser.call @, username
      else
        false
)()
###
_.extend Server,
  MISSING_PARAMETER: success: no, error: 'Missing a required parameter.'
  PERMISSION_DENIED: success: no, error: 'Permission denied.'