_       = require 'lodash'
$       = require 'jquery'
kd      = require 'kd'
kookies = require 'kookies'

RECAPTCHA_JS = 'https://www.google.com/recaptcha/api.js?onload=onRecaptchaLoaded&render=explicit'

PAYMENT_BACKEND_URI = '/api/social/payment'

createFormData = (teamData) ->

  teamData ?= utils.getTeamData()

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

recaptchaLoadCallbacks = []
window.onRecaptchaLoaded = ->

  callback() for callback in recaptchaLoadCallbacks
  recaptchaLoadCallbacks = []


savePaymentToken = (token) ->
  global._payment or= {}
  _payment.token = token

saveCardElement = (cardElement) ->
  global._payment or= {}
  global._payment.card = cardElement

getCardInfo = -> global._payment?.card

erasePaymentToken = -> delete global._payment?.token
eraseCardInfo = -> delete global._payment?.cardInfo

cleanPayment = ->
  erasePaymentToken()
  eraseCardInfo()
  delete global._payment

getPayment = -> global._payment ? {}


module.exports = utils = {

  savePaymentToken, saveCardElement, getPayment, cleanPayment

  clearKiteCaches: ->

    if window.localStorage?
      for kite in (Object.keys window.localStorage) when /^KITE_/.test kite
        delete window.localStorage[kite]


  analytics: require './analytics'


  getReferrer: ->

    match = location.pathname.match /\/R\/(.*)/
    return referrer  if match and referrer = match[1]


  getMainDomain: ->

    { hostname, port } = location
    kodingDomains      = ['dev', 'sandbox', 'latest', 'koding']
    prefix             = hostname.split('.').shift()

    domain = if prefix in kodingDomains
    then hostname
    else hostname.split('.').slice(1).join('.')

    return "#{domain}#{if port then ':'+port else ''}"


  getGroupNameFromLocation: (hostname) ->

    { hostname } = location  unless hostname
    basePattern  = (kd.config.domains.main.split ':')[0].replace /\./g, '\\.'

    predefinedPatterns = [
      # <team-domain>.koding.com
      # <team-domain>.<username>.koding.team
      # <team-domain>.<(dev|sandbox|latest|prod)>.koding.com
      {
        predict: "#{basePattern}"
        labelFn: (hostname) ->
          labels = hostname
            .replace ///\.?#{basePattern}$///, ''
            .split '.'
            .reverse()

          slug = labels.shift()
          if slug in ['dev', 'sandbox', 'latest', 'prod']
            slug = labels.shift()
          return slug
      }

      # <team-domain>.<IPv4>.xip.io
      # IPV4: A.B.C.D
      {
        predict: 'xip\.io'
        labelFn: (hostname) ->
          labels = hostname.split('.')
          labels.splice -6, 6 # 'A.B.C.D.xip.io'.length
          return labels.pop()
      }

      # <team-domain>.<IPv4>.nip.io
      # IPV4: A.B.C.D
      {
        predict: 'nip\.io'
        labelFn: (hostname) ->
          labels = hostname.split('.')
          labels.splice -6, 6 # 'A.B.C.D.nip.io'.length
          return labels.pop()
      }
    ]

    for pattern in predefinedPatterns

      { predict, labelFn } = pattern

      unless labelFn
        labelFn = do (predict) -> (hostname) ->
          hostname.replace(new RegExp("\\.?#{predict}$"), '').split('.').pop()

      if hostname.match new RegExp "#{predict}$"
        return labelFn(hostname) or 'koding'

    return 'koding'


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

        utils.validateEmail { email, tfcode: tfcodeValue, password : passValue },
          success : (res) ->

            return location.replace '/'  if res is 'User is logged in!'

            container.emit 'EmailIsAvailable'
            input.setValidationResult 'available', null

            container.emit 'EmailValidationPassed'  if res is yes

          error : ({ responseText }) ->

            return container.emit 'TwoFactorEnabled'  if /TwoFactor/i.test responseText

            container.emit 'EmailIsNotAvailable'
            input.setValidationResult 'available', "Sorry, #{email} is already in use!"



  checkedPasswords: {}
  checkPasswordStrength: kd.utils.debounce 300, (password, callback) ->

    return callback { msg : 'No password specified!' }  unless password
    return callback null, res                       if res = utils.checkedPasswords[password]

    $.ajax
      url         : '/-/password-strength'
      type        : 'POST'
      data        : { password }
      success     : (res) ->
        utils.checkedPasswords[res.password] = res
        callback null, res
      error       : ({ responseJSON }) -> callback { msg : responseJSON }


  storeNewTeamData: (formName, formData) ->

    kd.team              ?= {}
    { team }              = kd
    team[formName]        = formData

    try
      localStorage.teamData = JSON.stringify team


  clearTeamData: ->

    try
      localStorage.teamData = null

    kd.team = null


  getTeamData: ->

    attachPayment = (data, stripeToken) ->
      return _.assign {}, data, { payment: { stripeToken } }

    if team = kd.team
      token = getPayment()?.token
      isDefaultEnv = kd.config.environment is 'default'
      if not isDefaultEnv and token
        team = attachPayment kd.team, token
      return team

    return {}  unless data = localStorage.teamData

    try
      team    = JSON.parse data
      kd.team = team

    if team
      if token = getPayment()?.token
        team = attachPayment team, token
      return team

    return {}


  getPreviousTeams: ->

    try
      teams = JSON.parse kookies.get 'koding-teams'

    return teams  if teams and Object.keys(teams).length
    return null


  slugifyCompanyName: (team) ->

    if name = team.signup?.companyName
    then teamName = kd.utils.slugify name
    else teamName = ''

    return teamName


  createTeam: (callbacks = {}) ->

    isDefaultEnv = kd.config.environment is 'default'
    token = utils.getPayment()?.token

    if not isDefaultEnv and not token
      new kd.NotificationView { title : 'You need to enter your credit card!' }
      return kd.singletons.router.handleRoute '/Team/Payment'

    formData = createFormData()

    formData._csrf           = Cookies.get '_csrf'
    # manually add legacy fields - SY
    formData.agree           = 'on'
    formData.passwordConfirm = formData.password
    formData.redirect        = "#{location.protocol}//#{formData.slug}.#{location.host}?username=#{formData.username}"

    $.ajax
      url       : '/-/teams/create'
      data      : formData
      type      : 'POST'
      success   : callbacks.success or ->
        utils.clearTeamData()
        location.href = formData.redirect
      error     : callbacks.error  or ({ responseText }) ->
        new kd.NotificationView { title : responseText }


  routeIfInvitationTokenIsValid: (token, callbacks) ->

    $.ajax
      url       : '/-/teams/validate-token'
      data      : { token }
      type      : 'POST'
      success   : callbacks.success
      error     : callbacks.error


  fetchTeamMembers: ({ name, limit, token }, callback) ->

    $.ajax
      url       : "/-/team/#{name}/members?limit=#{limit ? 4}&token=#{token}"
      type      : 'POST'
      success   : (members) -> callback null, members
      error     : ({ responseText }) -> callback { msg : responseText }


  validateEmail: (data, callbacks) ->

    $.ajax
      url         : '/-/validate/email'
      type        : 'POST'
      data        : data
      xhrFields   : { withCredentials : yes }
      success     : callbacks.success
      error       : callbacks.error


  getProfile: (email, callbacks) ->

    $.ajax
      url         : "/-/profile/#{email}"
      type        : 'GET'
      success     : callbacks.success
      error       : callbacks.error


  unsubscribeEmail: (token, email, callbacks) ->

    $.ajax
      url         : "/-/unsubscribe/#{token}/#{email}"
      type        : 'GET'
      success     : callbacks.success
      error       : callbacks.error


  joinTeam: (callbacks = {}) ->

    formData = createFormData()

    formData._csrf           = Cookies.get '_csrf'
    # manually add legacy fields - SY
    formData.agree           = 'on'
    formData.passwordConfirm = formData.password
    formData.redirect        = '/'
    formData.slug            = kd.config.group.slug

    $.ajax
      url       : '/-/teams/join'
      data      : formData
      type      : 'POST'
      success   : callbacks.success or -> location.href = formData.redirect
      error     : callbacks.error   or ({ responseText }) ->
        new kd.NotificationView { title : responseText }


  earlyAccess: (data, callbacks = {}) ->

    data.campaign = 'teams-early-access'

    $.ajax
      url       : '/-/teams/early-access'
      data      : data
      type      : 'POST'
      success   : callbacks.success or ->
        new kd.NotificationView
          title    : "Thank you! We'll let you know when we launch it!"
          duration : 3000
      error     : callbacks.error   or ({ responseText }) ->
        if responseText is 'Already applied!'
          responseText = "Thank you! We'll let you know when we launch it!"
        new kd.NotificationView
          title    : responseText
          duration : 3000


  usernameCheck : (username, callbacks = {}) ->

    $.ajax
      url         : '/-/validate/username'
      type        : 'POST'
      data        : { username }
      success     : callbacks.success
      error       : callbacks.error


  verifySlug : (name, callbacks = {}) ->

    unless 2 < name.length
      return callbacks.error 'Domain name should be longer than 2 characters!'

    unless /^[a-z0-9][a-z0-9-]+$/.test name
      return callbacks.error 'Domain name is not valid, please try another one.'

    $.ajax
      url         : '/-/teams/verify-domain'
      type        : 'POST'
      data        : { name }
      success     : callbacks.success
      error       : (xhr) ->
        callbacks.error.call this, xhr.responseText


  getGravatarUrl : (size = 80, hash) ->

    fallback = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    return "//gravatar.com/avatar/#{hash}?size=#{size}&d=#{fallback}&r=g"


  getGroupLogo : ->

    { group } = kd.config
    logo      = new kd.CustomHTMLView { tagName : 'figure' }

    unless group
      logo.hide()
      return logo

    if group.customize?.logo
      logo.setCss 'background-image', "url(#{group.customize.logo})"
      logo.setCss 'background-size', 'cover'
    else
      # geoPattern = require 'geopattern'
      # pattern    = geoPattern.generate(group.slug, generator: 'plusSigns').toDataUrl()
      # logo.setCss 'background-image', pattern
      # logo.setCss 'background-size', 'inherit'
      logo.hide()

    return logo


  getAllowedDomainsPartial: (domains) -> ('<i>@' + d + '</i>, ' for d in domains).join('').replace(/,\s$/, '')


  # Used to store last used OAuth, ie 'github', 'facebook' etc. between refreshes.
  storeLastUsedProvider: (provider) ->
    window.localStorage.lastUsedProvider = provider


  getLastUsedProvider: -> window.localStorage.lastUsedProvider


  removeLastUsedProvider: -> delete window.localStorage.lastUsedProvider


  createTeamTitlePhrase: (title) ->

    # doesn't duplicate the word `the` if the title already has it in the beginning
    # doesn't duplicate the word `team` if the title already has it at the end
    "#{if title.search(/^the/i) < 0 then 'the' else ''} #{title} #{if title.search(/team$/i) < 0 then 'team' else ''}"

  # If current url contains redirectTo query parameter, use it to redirect after login.
  # If current url isn't loginRoute, login is shown because no route has matched current url.
  # It may happen when logged out user opens a page which requires user authentication.
  # Redirect to this url after user is logged in
  getLoginRedirectPath: (loginRoute) ->

    { redirectTo } = kd.utils.parseQuery()
    return redirectTo.substring 1  if redirectTo

    { pathname } = location
    if pathname and pathname.indexOf(loginRoute) is -1
      return pathname.substring 1


  repositionSuffix: (input, fakeView) ->

    input.getElement().removeAttribute 'size'

    element           = fakeView.getElement()
    element.innerHTML = input.getValue()

    { width }         = element.getBoundingClientRect()
    width             = if width then width + 3 else 100

    input.setWidth width


  loadRecaptchaScript: (callback) ->

    return callback()  if grecaptcha?

    recaptchaLoadCallbacks.push callback
    return  if recaptchaLoadCallbacks.length > 1

    recaptchaScript = new kd.CustomHTMLView
      tagName    : 'script'
      attributes :
        src      : RECAPTCHA_JS
        async    : yes
        defer    : yes

    recaptchaScript.appendToDomBody()

  makeChargeRequest: (token, email) -> new Promise (resolve, reject) ->
    options =
      url: "#{PAYMENT_BACKEND_URI}/creditcard/auth"
      type: 'POST'
      contentType: 'application/json'
      data: JSON.stringify { source: { token }, email }
      success: resolve
      error: (err) ->
        try
          reject JSON.parse err.responseJSON?.description
        catch err
          reject err

    $.ajax options

  loadStripe: do (client = null) -> -> new Promise (resolve, reject) ->

    return resolve(client)  if client

    global.document.head.appendChild (new kd.CustomHTMLView
      tagName    : 'script'
      attributes :
        type     : 'text/javascript'
        src      : 'https://js.stripe.com/v2/'
      bind       : 'load'
      load       : ->
        global.document.head.appendChild (new kd.CustomHTMLView
          tagName    : 'script'
          attributes :
            type     : 'text/javascript'
            src      : 'https://js.stripe.com/v3/'
          bind       : 'load'
          load       : ->
            client = Stripe kd.config.stripe.token
            return resolve(client)
        ).getElement()
    ).getElement()


  createStripeToken: (client, cardElement) -> new Promise (resolve, reject) ->
    client.createToken(cardElement).then (response) ->
      if response.error
      then reject response.error
      else resolve response.token.id


  submitWithDummyToken: (client) ->
    STRIPE_TEST_TOKEN = 'tok_visa'
    { email } = utils.getTeamData().signup

    utils.makeChargeRequest STRIPE_TEST_TOKEN, email
      .then -> utils.savePaymentToken STRIPE_TEST_TOKEN


  authorizeCreditCard: (client, cardElement) ->
    { email } = utils.getTeamData().signup

    utils.createStripeToken client, cardElement
      .then (token) -> utils.makeChargeRequest token, email
      # then create another token for subscription
      .then -> utils.createStripeToken client, cardElement
      .then (token) ->
        utils.savePaymentToken token
        utils.saveCardElement cardElement
      .catch (err) ->
        utils.cleanPayment()
        Promise.reject err


  getDummyCard: ->
    return {
      number: '4242424242424242'
      cvc: '111'
      exp_month: '11'
      exp_year: '21'
    }

}
