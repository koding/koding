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
    'x-requested-with': 'XMLHttpRequest'
    'user-agent'      : userAgent
    'content-type'    : 'application/x-www-form-urlencoded; charset=UTF-8'

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


  @generateCreateTeamRequestBody = (opts = {}) ->

    companyName = "testcompany#{generateRandomString(10)}"
    username    = generateRandomUsername()

    defaultBodyObject =
      email          :  generateRandomEmail()
      companyName    :  companyName
      alreadyMember  :  'false'
      slug           :  companyName
      allow          :  'true'
      domains        :  'koding.com, kd.io'
      invitees       :  'test@koding.com,test@test.com,'
      newsletter     :  'true'
      username       :  username
      password       :  'testpass'
      agree          :  'on'
      passwordConfirm:  'testpass'
      redirect       :  "#{generateUrl()}?username=#{username}"


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
      password          : 'testpass'
      inviteCode        : ''
      username          : generateRandomUsername()
      passwordConfirm   : 'testpass'
      agree             : 'on'

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
