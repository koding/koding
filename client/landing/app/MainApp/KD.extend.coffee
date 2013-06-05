# this class will register itself just before application starts loading, right after framework is ready
KD.extend
  impersonate : (username)->
    KD.remote.api.JAccount.impersonate username, (err)->
      if err then new KDNotificationView title: err.message
      else location.reload()

  notifyError_:(message)->
    console.log message
    new KDNotificationView
      type     : 'mini'
      cssClass : 'error'
      title    : message
      duration : 3500

  requireMembership:(options={})->

    {callback, onFailMsg, onFail, silence, tryAgain, groupName} = options
    unless KD.isLoggedIn()
      # if there is fail message, display it
      if onFailMsg
        @notifyError_ onFailMsg

      # if there is fail method, call it
      onFail?()

      # if login is a silent redirection
      unless silence
        @getSingleton('router').handleRoute "/Login", KD.config.entryPoint

      # if there is callback and we want to try again
      if callback? and tryAgain
        unless KD.lastFuncCall
          {mainController} = KD.singletons
          mainController.once "accountChanged.to.loggedIn", =>
            if groupName and KD.isLoggedIn()
              @joinGroup_ groupName, (res)=>
                unless res then return @notifyError_ "Joining to #{groupName} group failed"
                KD.lastFuncCall?()
                KD.lastFuncCall = null
        KD.lastFuncCall = callback
    else
      if groupName
        @joinGroup_ groupName, (res)=>
          if res then callback?()
          else @notifyError_ "Joining to #{groupName} group failed 2"
      else callback?()

  joinGroup_:(groupName, callback)->
    unless groupName then return callback true
    user = @whoami()
    user.fetchGroups (err, groups)=>
      if err or !groups then return callback false
      @remote.api.JGroup.one { slug: groupName }, (err, currentGroup)=>
        if err then return @notifyError_ err.message
        for group in groups
          if groupName is group.group.slug
            return callback true
        currentGroup.join (err)=>
          if err then return callback false
          @notifyError_ "Joined to #{groupName} group!"
          return callback true

  jsonhTest:->
    method    = 'fetchQuestionTeasers'
    testData  = {
      foo: 10
      bar: 11
    }

    start = Date.now()
    $.ajax "/#{method}.jsonh",
      data     : testData
      dataType : 'jsonp'
      success : (data)->
        inflated = JSONH.unpack data
        KD.log 'success', inflated
        KD.log Date.now()-start

  nick:-> KD.whoami().profile.nickname

  whoami:-> KD.getSingleton('mainController').userAccount

  logout:->
    mainController = KD.getSingleton('mainController')
    delete mainController?.userAccount

  isLoggedIn:-> KD.whoami() instanceof KD.remote.api.JAccount

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

  # private member for tracking z-indexes
  zIndexContexts  = {}

  # Get next highest Z-index
  getNextHighestZIndex:(context)->
   uniqid = context.data 'data-id'
   if isNaN zIndexContexts[uniqid]
     zIndexContexts[uniqid] = 0
   else
     zIndexContexts[uniqid]++
