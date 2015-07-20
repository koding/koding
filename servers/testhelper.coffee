_           = require 'underscore'
hat         = require 'hat'
querystring = require 'querystring'


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = (domain = 'koding.com') ->

  return "kodingtestuser+#{generateRandomString()}@#{domain}"


generateRandomUsername = -> generateRandomString()


generateUrl = (opts = {}) ->

  getRoute = (route) ->
    if    route
    then  "/#{route}"
    else  ''

  getSubdomain = (subdomain) ->
    if    subdomain
    then  "#{subdomain}."
    else  ''

  urlParts =
    host      : 'localhost'
    port      : ':8090'
    route     : ''
    protocol  : 'http://'
    subdomain : ''

  urlParts = _.extend urlParts, opts

  url =
    urlParts.protocol +
    getSubdomain(urlParts.subdomain) +
    urlParts.host +
    urlParts.port +
    getRoute(urlParts.route)

  return url


generateDefaultHeadersObject = (opts = {}) ->

  userAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3)
    AppleWebKit/537.36 (KHTML, like Gecko)
    Chrome/43.0.2357.81 Safari/537.36'

  defaultHeadersObject  =
    accept            : '*/*'
    'user-agent'      : userAgent
    'content-type'    : 'application/x-www-form-urlencoded; charset=UTF-8'
    'x-requested-with': 'XMLHttpRequest'

  defaultHeadersObject = deepObjectExtend defaultHeadersObject, opts

  return defaultHeadersObject


generateDefaultBodyObject = -> {}


generateDefaultRequestParams = (opts = {}) ->

  defaultBodyObject    = generateDefaultBodyObject()

  defaultHeadersObject = generateDefaultHeadersObject()

  defaultParams        =
    url               : generateUrl()
    body              : defaultBodyObject
    headers           : defaultHeadersObject

  defaultParams = deepObjectExtend defaultParams, opts

  return defaultParams


# _.extend didn't help with deep extend
# deep extending one object from another, works only for objects
deepObjectExtend = (target, source) ->

  for own prop of source

    # recursive call to deep extend
    if target[prop] and typeof source[prop] == 'object'
      deepObjectExtend target[prop], source[prop]
    # overwriting property
    else
      target[prop] = source[prop]

  return target


class RecoverHandlerHelper

  @defaultExpiryPeriod = 5 * 60 * 1000 # 5 minutes


  @generateRecoverRequestBody = (opts = {}) ->

    defaultBodyObject =
      email : ''

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateRecoverRequestParams = (opts = {}) ->

    email = opts?.body?.email or generateRandomEmail()

    url  = generateUrl
      route : "#{encodeURIComponent email}/Recover"

    body = RecoverHandlerHelper.generateRecoverRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


class ResetHandlerHelper

  @generateResetRequestBody = (opts = {}) ->

    defaultBodyObject =
      password      : generateRandomString()
      recoveryToken : generateRandomString()

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateResetRequestParams = (opts = {}) ->

    token = opts?.body?.email or 'someToken'

    url  = generateUrl
      route : "#{encodeURIComponent token}/Reset"

    body = ResetHandlerHelper.generateResetRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


class ValidationHandlerHelper

  @generateVerifyTokenRequestBody = (opts = {}) ->

    defaultBodyObject =
      token : ''

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateVerifyTokenRequestParams = (opts = {}) ->

    { token } = opts
    delete opts.token

    url  = generateUrl
      route : "Verify/#{token}"

    body = ValidationHandlerHelper.generateVerifyTokenRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateValidateRequestBody = (opts = {}) ->

    defaultBodyObject =
      fields     :
        username : ''
        email    : ''

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateValidateRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/validate'

    body = ValidationHandlerHelper.generateValidateRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateValidateUsernameRequestBody = (opts = {}) ->

    defaultBodyObject =
      username : generateRandomUsername()

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateValidateUsernameRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/validate/username'

    body = ValidationHandlerHelper.generateValidateUsernameRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateValidateEmailRequestBody = (opts = {}) ->

    defaultBodyObject =
      email     : generateRandomEmail()
      tfcode    : ''
      password  : ''

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateValidateEmailRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/validate/email'

    body = ValidationHandlerHelper.generateValidateEmailRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


class TeamHandlerHelper

  @convertToArray = (commaSeparatedData = '')->

    return []  if commaSeparatedData is ''

    data = commaSeparatedData.split(',') or []

    data = data
      .filter (s) -> s isnt ''           # clear empty ones
      .map (s) -> s.trim().toLowerCase() # clear empty spaces

    return data


  @generateCheckTokenRequestBody = (opts = {}) ->

    defaultBodyObject =
      token : generateRandomString()

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateCheckTokenRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/teams/validate-token'

    body = TeamHandlerHelper.generateCheckTokenRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateJoinTeamRequestBody = (opts = {}) ->

    username = generateRandomUsername()

    defaultBodyObject =
      slug                : "testcompany#{generateRandomString(10)}"
      email               : generateRandomEmail()
      token               : ''
      allow               : 'true'
      agree               : 'on'
      username            : username
      password            : 'testpass'
      redirect            : ''
      newsletter          : 'true'
      alreadyMember       : 'false'
      passwordConfirm     : 'testpass'

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateJoinTeamRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/teams/join'

    body = TeamHandlerHelper.generateCreateTeamRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateGetTeamRequestParams = (opts = {}) ->

    { groupSlug } = opts
    url  = generateUrl
      route : "-/team/#{groupSlug}"

    params               = { url }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateGetTeamMembersRequestBody = (opts = {}) ->

    defaultBodyObject =
      limit : '10'
      token : ''

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateGetTeamMembersRequestParams = (opts = {}) ->

    { groupSlug } = opts
    delete opts.groupSlug

    url  = generateUrl
      route : "-/team/#{groupSlug}/members"

    body = TeamHandlerHelper.generateGetTeamMembersRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateCreateTeamRequestBody = (opts = {}) ->

    username    = generateRandomUsername()
    invitees    = "#{generateRandomEmail('koding.com')},#{generateRandomEmail('gmail.com')}"
    companyName = "testcompany#{generateRandomString(10)}"

    defaultBodyObject =
      slug           :  companyName
      email          :  generateRandomEmail()
      agree          :  'on'
      allow          :  'true'
      domains        :  'koding.com, gmail.com'
      invitees       :  invitees
      redirect       :  ''
      username       :  username
      password       :  'testpass'
      newsletter     :  'true'
      companyName    :  companyName
      alreadyMember  :  'false'
      passwordConfirm:  'testpass'

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  # overwrites given options in the default params
  @generateCreateTeamRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/teams/create'

    body = TeamHandlerHelper.generateCreateTeamRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultRequestParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


class LoginHandlerHelper

  @generateLoginRequestBody = (opts = {}) ->

    defaultBodyObject =
      token               : ''
      tfcode              : ''
      username            : generateRandomUsername()
      password            : 'testpass'
      redirect            : ''
      groupName           : 'koding'

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  # overwrites given options in the default params
  @generateLoginRequestParams = (opts = {}) ->

    url  = generateUrl
      route : 'Login'

    body = LoginHandlerHelper.generateLoginRequestBody()

    params                = { url, body }
    defaultRequestParams  = generateDefaultRequestParams params
    requestParams         = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body    = querystring.stringify requestParams.body

    return requestParams


class RegisterHandlerHelper

  @generateRegisterRequestBody = (opts = {}) ->

    defaultBodyObject =
      email             : generateRandomEmail()
      agree             : 'on'
      username          : generateRandomUsername()
      password          : 'testpass'
      inviteCode        : ''
      passwordConfirm   : 'testpass'

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  # overwrites given options in the default params
  @generateRegisterRequestParams = (opts = {}) ->

    url  = generateUrl
      route : 'Register'

    body = RegisterHandlerHelper.generateRegisterRequestBody()

    params                = { url, body }
    defaultRequestParams  = generateDefaultRequestParams params
    requestParams         = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body    = querystring.stringify requestParams.body

    return requestParams


module.exports = {
  generateUrl
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDefaultRequestParams

  TeamHandlerHelper
  LoginHandlerHelper
  ResetHandlerHelper
  RecoverHandlerHelper
  RegisterHandlerHelper
  ValidationHandlerHelper
}
