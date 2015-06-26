_           = require 'underscore'
hat         = require 'hat'
querystring = require 'querystring'


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = -> "testuser+#{generateRandomString()}@koding.com"


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


generateDefaultParams = (opts = {}) ->

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
      token :  generateRandomString()

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateCheckTokenRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/teams/validate-token'

    body = TeamHandlerHelper.generateCheckTokenRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateJoinTeamRequestBody = (opts = {}) ->

    username = generateRandomUsername()

    defaultBodyObject =
      slug           :  "testcompany#{generateRandomString(10)}"
      email          :  generateRandomEmail()
      token          :  ''
      allow          :  'true'
      agree          :  'on'
      username       :  username
      password       :  'testpass'
      redirect       :  ''
      newsletter     :  'true'
      alreadyMember  :  'false'
      passwordConfirm:  'testpass'

    deepObjectExtend defaultBodyObject, opts

    return defaultBodyObject


  @generateJoinTeamRequestParams = (opts = {}) ->

    url  = generateUrl
      route : '-/teams/join'

    body = TeamHandlerHelper.generateCreateTeamRequestBody()

    params               = { url, body }
    defaultRequestParams = generateDefaultParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateGetTeamRequestParams = (opts = {}) ->

    { groupSlug } = opts
    url  = generateUrl
      route : "-/teams/#{groupSlug}"

    params               = { url }
    defaultRequestParams = generateDefaultParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


  @generateCreateTeamRequestBody = (opts = {}) ->

    username    = generateRandomUsername()
    companyName = "testcompany#{generateRandomString(10)}"

    defaultBodyObject =
      slug           :  companyName
      email          :  generateRandomEmail()
      agree          :  'on'
      allow          :  'true'
      domains        :  'koding.com, kd.io'
      invitees       :  'test@koding.com,test@test.com,'
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
    defaultRequestParams = generateDefaultParams params
    requestParams        = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body   = querystring.stringify requestParams.body

    return requestParams


class RegisterHandlerHelper

  @generateRequestBody = (opts = {}) ->

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
  @generateRequestParams = (opts = {}) ->

    url  = generateUrl
      route : 'Register'

    body = RegisterHandlerHelper.generateRequestBody()

    params                = { url, body }
    defaultRequestParams  = generateDefaultParams params
    requestParams         = deepObjectExtend defaultRequestParams, opts
    # after deep extending object, encodes body param to a query string
    requestParams.body    = querystring.stringify requestParams.body

    return requestParams


module.exports = {
  TeamHandlerHelper
  generateRandomEmail
  generateRandomString
  RegisterHandlerHelper
}
