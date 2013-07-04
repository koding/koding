# this class will register itself just before application starts loading, right after framework is ready
KD.extend

  impersonate : (username)->
    KD.remote.api.JAccount.impersonate username, (err)->
      if err then new KDNotificationView title: err.message
      else location.reload()

  notify_:(message, type)->
    console.log message
    new KDNotificationView
      cssClass : "#{type}"
      title    : message
      duration : 3500

  requireMembership:(options={})->

    {callback, onFailMsg, onFail, silence, tryAgain, groupName} = options
    unless KD.isLoggedIn()
      # if there is fail message, display it
      if onFailMsg
        @notify_ onFailMsg, "error"

      # if there is fail method, call it
      onFail?()

      # if it's not a silent operation redirect
      unless silence
        KD.getSingleton('router').handleRoute "/Login", KD.config.entryPoint

      # if there is callback and we want to try again
      if callback? and tryAgain
        unless KD.lastFuncCall
          mainController = KD.getSingleton("mainController")
          mainController.once "accountChanged.to.loggedIn", =>
            if groupName and KD.isLoggedIn()
              @joinGroup_ groupName, (res)=>
                unless res then return @notify_ "Joining to #{groupName} group failed", "error"
                KD.lastFuncCall?()
                KD.lastFuncCall = null
        KD.lastFuncCall = callback
    else
      if groupName
        @joinGroup_ groupName, (res)=>
          if res

            callback?()
          else @notify_ "Joining to #{groupName} group failed", "error"
      else callback?()

  joinGroup_:(groupName, callback)->
    unless groupName then return callback true
    user = @whoami()
    user.fetchGroups (err, groups)=>
      if err or !groups then return callback false
      @remote.api.JGroup.one { slug: groupName }, (err, currentGroup)=>
        if err then return @notify_ err.message, "error"
        for group in groups
          if groupName is group.group.slug
            return callback true
        currentGroup.join (err)=>
          if err then return callback false
          @notify_ "You have joined to #{groupName} group!", "success"
          return callback true

  nick:-> KD.whoami().profile.nickname

  whoami:-> KD.getSingleton('mainController').userAccount

  logout:->
    mainController = KD.getSingleton('mainController')
    delete mainController?.userAccount

  isLoggedIn:-> KD.whoami().type isnt 'unregistered'

  isMine:(account)-> KD.whoami().profile.nickname is account.profile.nickname

  checkFlag:(flagToCheck, account = KD.whoami())->
    if account.globalFlags
      if 'string' is typeof flagToCheck
        return flagToCheck in account.globalFlags
      else
        for flag in flagToCheck
          if flag in account.globalFlags
            return yes
    no

  showError:(err, messages)->
    return  unless err

    if 'string' is typeof err
      message = err
      err     = {message}

    err.name or= 'KodingError'
    message    = messages[err.name] or err.message or 'Something went wrong'

    new KDNotificationView
      title : message

    warn "KodingError:", err.message  unless err.name is 'AccessDenied'
