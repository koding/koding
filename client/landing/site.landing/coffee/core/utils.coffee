utils.extend utils,


  clearKiteCaches: ->

    if window.localStorage?
      for kite in (Object.keys window.localStorage) when /^KITE_/.test kite
        delete window.localStorage[kite]


  trackEvent: (args...) ->

    return  unless @trackEligible()

    # send event#action as event for GA
    if args.length > 1
      {action} = args[1]
      args[1].event = args[0]  unless args[1].event

    # if event#action, send that or fallback to event
    event = if action? then action else args[0]
    analytics.track event, args[1]


  trackPage: (args) ->

    return  unless @trackEligible()

    {path} = args
    return  unless path

    title = @getFirstPartOfpath(path)
    analytics.page(title, {title:document.title, path})


  trackEligible: ->

    return analytics? and KD.config.environment is "production"

  getFirstPartOfpath: (path)-> return path.split('/')[1] or '/'


  getReferrer: ->

    match = location.pathname.match /\/R\/(.*)/
    return referrer  if match and referrer = match[1]


  getGroupNameFromLocation: ->

    { hostname } = location
    mainDomains = ['dev.koding.com', 'sandbox.koding.com', 'latest.koding.com', 'prod.koding.com']
    groupName = if hostname in mainDomains then 'koding'
    else if hostname.indexOf('.dev.koding.com') isnt -1
    then hostname.replace('.dev.koding.com', '').split('.').last
    else if hostname.indexOf('.sandbox.koding.com') isnt -1
    then hostname.replace('.sandbox.koding.com', '').split('.').last
    else if hostname.indexOf('.latest.koding.com') isnt -1
    then hostname.replace('.latest.koding.com', '').split('.').last
    else if hostname.indexOf('.koding.com') isnt -1
    then hostname.replace('.koding.com', '').split('.').last
    else 'koding'

    return groupName


  checkIfGroupExists: (groupName, callback) ->

    $.ajax
      url     : "/-/team/#{groupName}"
      type    : 'post'
      success : (group) -> callback null, group
      error   : (err)   -> callback err


  getEmailValidator: (options = {}) ->

    { container, password, tfcode } = options

    container   : container
    event       : 'submit'
    messages    :
      required  : 'Please enter your email address.'
      email     : 'That doesn\'t seem like a valid email address.'
    rules       :
      required  : yes
      email     : yes
      available : (input, event) ->

        return  if event?.which is 9

        { required, email, minLength } = input.validationResults

        return  if required or minLength

        input.setValidationResult 'available', null

        email         = input.getValue()
        passValue     = password.input.getValue()  if password
        tfcodeValue   = tfcode.input.getValue()  if tfcode

        container.emit 'EmailIsNotAvailable'

        return  unless input.valid

        KD.utils.validateEmail { email, tfcode: tfcodeValue, password : passValue },
          success : (res) ->

            return location.replace '/'  if res is 'User is logged in!'

            container.emit 'EmailIsAvailable'
            input.setValidationResult 'available', null

            container.emit 'EmailValidationPassed'  if res is yes

          error : ({responseText}) ->

            return container.emit 'TwoFactorEnabled'  if /TwoFactor/i.test responseText

            container.emit 'EmailIsNotAvailable'
            input.setValidationResult 'available', "Sorry, #{email} is already in use!"



  checkedPasswords: {}
  checkPasswordStrength: KD.utils.debounce 300, (password, callback) ->

    return callback msg : 'No password specified!'  unless password
    return callback null, res                       if res = KD.utils.checkedPasswords[password]

    $.ajax
      url         : "/-/password-strength"
      type        : 'POST'
      data        : { password }
      success     : (res) ->
        KD.utils.checkedPasswords[res.password] = res
        callback null, res
      error       : ({responseJSON}) -> callback msg : responseJSON


  storeNewTeamData: (formName, formData) ->

    KD.team              ?= {}
    { team }              = KD
    team[formName]        = formData
    localStorage.teamData = JSON.stringify team


  clearTeamData: ->

    localStorage.teamData = null
    KD.team               = null


  getTeamData: ->

    return KD.team  if KD.team

    return {}  unless data = localStorage.teamData

    try
      team    = JSON.parse data
      KD.team = team

    return team  if team
    return {}


  createFormData = (teamData) ->

    teamData ?= KD.utils.getTeamData()
    formData  = {}

    for own step, fields of teamData when not ('boolean' is typeof fields)
      for own field, value of fields
        if step is 'invite'
          unless formData.invitees
          then formData.invitees  = value
          else formData.invitees += ",#{value}"
        else
          formData[field] = value

    return formData


  createTeam: (callbacks = {}) ->

    formData = createFormData()

    # manually add legacy fields - SY
    formData.agree           = 'on'
    formData.passwordConfirm = formData.password
    formData.redirect        = "#{location.protocol}//#{formData.slug}.#{location.host}?username=#{formData.username}"

    $.ajax
      url       : "/-/teams/create"
      data      : formData
      type      : 'POST'
      success   : callbacks.success or ->
        KD.utils.clearTeamData()
        location.href = formData.redirect
      error     : callbacks.error  or ({responseText}) ->
        new KDNotificationView title : responseText


  routeIfInvitationTokenIsValid: (token) ->

    $.ajax
      url       : "/-/teams/validate-token"
      data      : { token }
      type      : 'POST'
      success   : ({email}) ->
        KD.utils.storeNewTeamData 'invitation', { token, email }
        KD.singletons.router.handleRoute '/Welcome'
      error     : ({responseText}) ->
        new KDNotificationView title : responseText
        KD.singletons.router.handleRoute '/'


  fetchTeamMembers: ({name, limit, token}, callback) ->

    $.ajax
      url       : "/-/team/#{name}/members?limit=#{limit ? 4}&token=#{token}"
      type      : 'POST'
      success   : (members) -> callback null, members
      error     : ({responseText}) -> callback msg : responseText


  validateEmail: (data, callbacks) ->

    $.ajax
      url         : "/-/validate/email"
      type        : 'POST'
      data        : data
      xhrFields   : withCredentials : yes
      success     : callbacks.success
      error       : callbacks.error


  joinTeam: (callbacks = {}) ->

    formData = createFormData()

    # manually add legacy fields - SY
    formData.agree           = 'on'
    formData.passwordConfirm = formData.password
    formData.redirect        = '/'

    $.ajax
      url       : "/-/teams/join"
      data      : formData
      type      : 'POST'
      success   : callbacks.success or -> location.href = formData.redirect
      error     : callbacks.error   or ({responseText}) ->
        new KDNotificationView title : responseText


  earlyAccess: (data, callbacks = {}) ->

    data.campaign = 'teams-early-access'

    $.ajax
      url       : "/-/teams/early-access"
      data      : data
      type      : 'POST'
      success   : callbacks.success or ->
        new KDNotificationView
          title    : "Thank you! We'll let you know when we launch it!"
          duration : 3000
      error     : callbacks.error   or ({responseText}) ->
        if responseText is 'Already applied!'
          responseText = "Thank you! We'll let you know when we launch it!"
        new KDNotificationView
          title    : responseText
          duration : 3000


  usernameCheck : (username, callbacks = {}) ->

    $.ajax
      url         : "/-/validate/username"
      type        : 'POST'
      data        : { username }
      success     : callbacks.success
      error       : callbacks.error


  verifySlug : (name, callbacks = {}) ->

    $.ajax
      url         : "/-/teams/verify-domain"
      type        : 'POST'
      data        : { name }
      success     : callbacks.success
      error       : callbacks.error


  getGroupLogo : ->

    { group } = KD.config
    logo      = new KDCustomHTMLView tagName : 'figure'

    if group.customize?.logo
      logo.setCss 'background-image', "url(#{group.customize.logo})"
      logo.setCss 'background-size', 'cover'
    else
      geoPattern = require 'geopattern'
      pattern    = geoPattern.generate(group.slug, generator: 'plusSigns').toDataUrl()
      logo.setCss 'background-image', pattern
      logo.setCss 'background-size', 'inherit'

    return logo
