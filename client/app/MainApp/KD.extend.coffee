# this class will register itself just before application starts loading, right after framework is ready
KD.extend

  apiUri  : KD.config.apiUri
  appsUri : KD.config.appsUri

  impersonate : (username)->
    KD.remote.api.JAccount.impersonate username, (err)->
      if err then new KDNotificationView title: err.message
      else location.reload()

  notify_:(message, type='')->
    log message
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

  nick:-> KD.whoami().profile.nickname

  whoami:-> KD.getSingleton('mainController').userAccount

  logout:->
    mainController = KD.getSingleton('mainController')
    delete mainController?.userAccount

  isGuest:-> not KD.isLoggedIn()
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
    return no  unless err

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

    warn "KodingError:", err.message  unless err.name is 'AccessDenied'
    err?

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

  runningInFrame: -> window.top isnt window.self

  getGroup: -> (KD.getSingleton 'groupsController').getCurrentGroup()

Object.defineProperty KD, "defaultSlug",
  get:->
    if KD.isGuest() then 'guests' else 'koding'
