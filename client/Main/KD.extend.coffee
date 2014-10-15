# this class will register itself just before application starts loading, right after framework is ready

# if localStorage.disableWebSocket?
#   if localStorage.disableWebSocket is "true"
#     window.WebSocket = null
# else if KD.config.kites.disableWebSocketByDefault
#   window.WebSocket = null

KD.extend

  useNewKites  : do ->
    useNewKites = switch
      when KD.config.kites.stack.force
        Boolean KD.config.kites.stack.newKites
      when localStorage.useNewKites?
        Boolean Number localStorage.useNewKites
    localStorage.useNewKites = if useNewKites then '1' else ''
    return useNewKites
  useWebSockets : yes

  toggleKiteStack: ->
    localStorage.useNewKites =
      if @useNewKites
      then ''
      else '1'
    location.reload()

  socketConnected:->
    @backendIsConnected = yes

  # Rewrites console.log to send logs to backend and also browser console.
  enabledBackendLogger: (backendLoggerClass)->
    oldConsoleLog = console.log
    frontloggerConsoleLog = (args...)->
      return unless KD.logsEnabled
      oldConsoleLog.apply this, arguments
      backendLoggerClass.info.apply backendLoggerClass, arguments

    console.log = frontloggerConsoleLog

    return "Logs are logged to backend too."

  impersonate : (username)->
    KD.remote.api.JAccount.impersonate username, (err)=>
      if err
        options = userMessage: "You are not allowed to impersonate"
        @showErrorNotification err, options
      else location.reload()

  notify_:(message, type='', duration = 3500)->
    new KDNotificationView
      cssClass : type
      title    : message
      duration : duration

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
        KD.getSingleton('router').handleRoute "/Login",
          entryPoint : KD.config.entryPoint

      # if there is callback and we want to try again
      if callback? and tryAgain
        unless KD.lastFuncCall
          KD.lastFuncCall = callback

          mainController = KD.getSingleton("mainController")
          mainController.once "accountChanged.to.loggedIn", =>
            if KD.isLoggedIn()
              KD.lastFuncCall?()
              KD.lastFuncCall = null
              if groupName
                @joinGroup_ groupName, (err) =>
                  return @notify_ "Joining #{groupName} group failed", "error"  if err
    else if groupName
      @joinGroup_ groupName, (err)=>
        return @notify_ "Joining #{groupName} group failed", "error"  if err
        callback?()
    else
      callback?()

  joinGroup_:(groupName, callback)->
    return callback null unless groupName
    user = @whoami()
    user.checkGroupMembership groupName, (err, isMember)=>
      return callback err  if err
      return callback null if isMember

      #join to group
      @remote.api.JGroup.one { slug: groupName }, (err, currentGroup)=>
        return callback err if err
        return callback null unless currentGroup
        currentGroup.join (err)=>
          return callback err if err
          @notify_ "You have joined to #{groupName} group!", "success"
          return callback null

  nick:-> KD.whoami()?.profile?.nickname

  logout:->
    mainController = KD.getSingleton('mainController')
    mainController.isLoggingIn on
    delete KD.userAccount


  isGroup: ->

    {entryPoint} = KD.config
    return entryPoint?.type is 'group'


  isKoding: ->

    {entryPoint} = KD.config
    return entryPoint?.slug is 'koding'


  isMember: ->

    {roles} = KD.config
    return 'member' in roles


  isGuest:-> not KD.isLoggedIn()

  isMine:(target)->
    if target?.bongo_?.constructorName is 'JAccount'
      KD.whoami().profile.nickname is target.profile.nickname
    else if target?.originId?
      KD.whoami()._id is target.originId

  isMyPost: (post) -> post.account._id is KD.whoami().getId() and post.typeConstant not in ['join', 'leave']

  isMyChannel: (channel) -> channel.creatorId is KD.whoami().socialApiId

  checkFlag:(flagToCheck, account = KD.whoami())->
    if account.globalFlags
      if 'string' is typeof flagToCheck
        return flagToCheck in account.globalFlags
      else
        for flag in flagToCheck
          if flag in account.globalFlags
            return yes
    return no

  # filterTrollActivity filters troll activities from users.
  # Only super-admins and other trolls can see these activities
  filterTrollActivity:(account)->
    return no unless account.isExempt
    return account._id isnt KD.whoami()._id and not KD.checkFlag "super-admin"

  showError:(err, messages)->
    return no  unless err

    if Array.isArray err
      @showError er  for er in err
      return err.length

    if 'string' is typeof err
      message = err
      err     = {message}

    defaultMessages =
      AccessDenied : 'Permission denied'
      KodingError  : 'Something went wrong'

    err.name or= 'KodingError'
    content    = ''

    if messages
      errMessage = messages[err.name] or messages.KodingError \
                                      or defaultMessages.KodingError
    messages or= defaultMessages
    errMessage or= err.message or messages[err.name] or messages.KodingError

    if errMessage?
      if 'string' is typeof errMessage
        title = errMessage
      else if errMessage.title? and errMessage.content?
        {title, content} = errMessage

    duration = errMessage.duration or 2500
    title  or= err.message

    new KDNotificationView {title, content, duration}

    unless err.name is 'AccessDenied'
      warn "KodingError:", err.message
      error err
    err?

  showNotification: (message, options = {})->
    return  if not message or message is ""

    # TODO these css/type parameters will be changed according to error type
    type = 'growl'

    options.duration or= 3500
    options.title      = message
    # options.css      or= css
    options.type     or= type

    options.fn message  if options.fn and typeof options.fn? is 'function'

    new KDNotificationView options

  # TODO after error message handling method is decided replace this function
  # with showError
  showErrorNotification: (err, options = {}) ->
    {message, name} = err  if err

    switch name
      when 'AccessDenied'
        options.fn = warn
        options.type = 'growl'
        message = options.userMessage
      else
        options.userMessage = "Error, please try again later!"
        options.fn = error

    @showNotification message, options

  getPathInfo: (fullPath)->
    return no unless fullPath
    path      = FSHelper.plainPath fullPath
    basename  = FSHelper.getFileNameFromPath fullPath
    parent    = FSHelper.getParentPath path
    vmName    = FSHelper.getVMNameFromPath fullPath
    isPublic  = FSHelper.isPublicPath fullPath
    {path, basename, parent, vmName, isPublic}

  getPublicURLOfPath: (fullPath, secure=no)->
    {vmName, isPublic, path} = KD.getPathInfo fullPath
    return unless isPublic
    pathPartials = path.match /^\/home\/(\w+)\/Web\/(.*)/
    return unless pathPartials
    [_, user, publicPath] = pathPartials

    publicPath or= ""
    subdomain =
      if /^shared\-/.test(vmName) and user is KD.nick()
      then "#{user}."
      else ""

    return "#{if secure then 'https' else 'http'}://#{subdomain}#{vmName}/#{publicPath}"

  getGroup: -> KD.currentGroup

  getReferralUrl: (username) ->
    "#{location.origin}/R/#{username}"

  hasAccess:(permission)->
    if "admin" in KD.config.roles then yes else permission in KD.config.permissions

  getMessageOwner: (message, callback) ->
    {constructorName, _id} = message.account
    KD.remote.cacheable constructorName, _id, (err, owner) ->
      return callback err  if err
      return callback {message: "Account not found", name: "NotFound"} unless owner
      callback null, owner


Object.defineProperty KD, "defaultSlug",
  get:->
    if KD.isGuest() then 'guests' else 'koding'
