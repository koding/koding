class KiteController extends KDController

  # notification = null
  notify = (msg)->

    # notification.destroy() if notification
    notification = new KDNotificationView
      title     : msg or "Something went wrong"
      type      : "growl"
      cssClass  : "mini"
      duration  : 2500

  constructor:->

    super
    @account = KD.whoami()
    @kiteIds = {}
    @setListeners()
    @status = no
    @intervals = {}
  
  setListeners:->

    mainController = @getSingleton "mainController"
    mainController.getVisitor().on 'change.login', (account)=> 
      @accountChanged account
  
  accountChanged:(account)->

    @account = account
    kiteName = "sharedHosting"
    if KD.isLoggedIn()
      @resetKiteIds kiteName, (err, res)=>
        unless err
          @status = yes
          @propagateEvent KDEventType : "SharedHostingIsReady"
    else
      @status = no
  
  resetKiteIds:(kiteName = "sharedHosting", callback)->
#
#    @account.fetchKiteIds {kiteName}, (err,kiteIds)=>
#      if err
#        notify "Backend is not responding, trying to fix..."
#      else
#        notify "Backend servers are ready."
#        @kiteIds[kiteName] = kiteIds
#      callback err, kiteIds
#  
  run:(options = {}, callback)->

    options.kiteName or= "sharedHosting"
    options.kiteId   or= @kiteIds.sharedHosting?[0]
    options.toDo     or= "executeCommand"
    options.withArgs or= {}

    @account.tellKite options, (err, response)=>
      @parseKiteResponse {err, response}, options, callback
  
  parseKiteResponse:({err, response}, options, callback)->

    if err and response
        callback? err, response
        warn "there were some errors parsing kite response:", err
    else if err
      if err.kiteNotPresent
        @handleKiteNotPresent {err, response}, options, callback
      else if /No\ssuch\suser/.test err
        @handleNoSuchUser {err, response}, options, callback
      else
        callback? err
        warn "parsing kite response: we dont handle this yet", err
    else
      @status = yes
      callback? err, response

  handleKiteNotPresent:({err, response}, options, callback)->

    # log "handleKiteNotPresent"
    notify "Backend is not responding, trying to fix..."
    @resetKiteIds options.kiteName, (err, kiteIds)=>
      if Array.isArray(kiteIds) and kiteIds.length > 0
        # warn kiteIds, ">>>>>"
        @run options, callback
      else
        notify "Backend is not responding, try again later."
        warn "handleKiteNotPresent: we dont handle this yet", err
        callback? "handleKiteNotPresent: we dont handle this yet"
  
  createSystemUser:(callback)->

    @run
      toDo       : "createSystemUser"
      withArgs   :
        fullName : "#{@account.getAt 'profile.firstName'} #{@account.getAt 'profile.lastName'}"
        password : __utils.getRandomHex().substr(1)
    , (err, res)=>
      callback? err, res
      unless err
        notify "User environment is created"
        @propagateEvent KDEventType : "UserEnvironmentIsCreated"
        # @run options, callback
      else
        error "createUserEnvironment", err
        notify "Something went wrong creating user environment, trying to fix..."
    
  
  handleNoSuchUser:({err, response}, options, callback)->

    # log "handleNoSuchUser"
    notify "Creating the user environment."
    @run
      toDo       : "createSystemUser"
      withArgs   :
        fullName : "#{@account.profile.firstName} #{@account.profile.lastName}"
        password : __utils.getRandomHex().substr(1)
    , (err, res)=>
      unless err
        notify "User environment is created"
        @propagateEvent KDEventType : "UserEnvironmentIsCreated"
        @run options, callback
      else
        error "createUserEnvironment", err
        notify "Something went wrong creating user environment, trying to fix..."
    

  ping:(kiteName, callback)->

    log "pinging : #{kiteName}"
    @run toDo : "_ping", (err, res)=>
      unless err
        @status = yes
        clearInterval @pinger if @pinger
        # @propagateEvent KDEventType : "SharedHostingIsWorking"
        notify "Shared hosting is alive!"

      else
        notify "Checking if servers are back..."
        @parseError @, err
      callback?()

  setPinger:->

    return if @pinger
    @pinger = setInterval => 
      @ping()
    , 10000
    @ping()

  # createUserEnvironment:(callback)->
  #   setTimeout =>
  #     notify "Creating the user environment."
  #   ,500
  #   @run
  #     toDo       : "createSystemUser"
  #     withArgs   :
  #       fullName : "#{@account.profile.firstName} #{@account.profile.lastName}"
  #       password : __utils.getRandomHex().substr(1)
  #   , (err, res)=>
  #     unless err
  #       notify "User environment is created"
  #       @propagateEvent KDEventType : "UserEnvironmentIsCreated"
  #       callback? err, res
  #     else
  #       error "createUserEnvironment", err
  #       notify "Something went wrong creating user environment, trying to fix..."
  #       @parseError @, err
  #     @ping()
  # 
  # parseError:(pubInst, err)->
  #   if err.kiteNotPresent
  #     {kiteName} = err
  #     log "<<<>>>>",@kiteIds[kiteName],err
  #     if @kiteIds[kiteName]? and err.kiteId in @kiteIds[kiteName]
  #       log "kite id removed", @kiteIds[kiteName].splice @kiteIds[kiteName].indexOf(err.kiteId),1
  # 
  #     # if @kiteIds[kiteName].length is 0
  #     #   @account.fetchKiteIds {kiteName}, (err,kiteIds)=>
  #     #     if err
  #     #       notify "Backend is not responding, trying to fix..."
  #     #     else
  #     #       @kiteIds[kiteName] = kiteIds
  #     #       log "kiteIds fetched", kiteIds
  #     # else
  #       @status = no
  #       notify "Server for this account is not yet ready, trying to fix..."
  #       @setPinger()
  #   else
  #     if /No\ssuch\suser/.test err
  #       notify "Couldn't find the user environment!"
  #       eventName = "NoSuchUser"
  #       @createUserEnvironment()
  # 
  #     if eventName
  #       @propagateEvent KDEventType : eventName, err
  # 
  # jailInterval:(kiteName, callback)=>
  #   log "jailed"
  #   @intervals[kiteName] = setInterval callback, 1000 unless @intervals[kiteName]
  # 
  # killInterval:(kiteName)=>
  #   log "killed"
  #   clearInterval @intervals[kiteName] if @intervals[kiteName]


