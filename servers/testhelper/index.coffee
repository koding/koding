_           = require 'underscore'
url         = require 'url'
hat         = require 'hat'
async       = require 'async'
Bongo       = require 'bongo'
request     = require 'request'
querystring = require 'querystring'

{ argv }   = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
mongo       = KONFIG.mongoReplSet or "mongodb://#{ KONFIG.mongo }"
{ expect }  = require 'chai'


checkBongoConnectivity = (callback) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    callback()


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = (domain = 'koding.com') ->

  return "kodingtestuser+#{generateRandomString()}@#{domain}"


generateRandomUsername = -> generateRandomString()


generateUrl = (opts = {}) ->
  uri = url.parse(KONFIG.uri.address)
  uri.host = "#{opts.subdomain}.#{uri.host}"  if opts.subdomain
  uri.pathname = opts.route
  return url.format(uri)


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


generateRequestParamsEncodeBody = (params, opts = {}) ->

  defaultRequestParams  = generateDefaultRequestParams params
  requestParams         = deepObjectExtend defaultRequestParams, opts

  if csrfCookieValue = requestParams.csrfCookie
    cookie             = generateCsrfTokenCookie csrfCookieValue
    requestParams.jar ?= request.jar()
    requestParams.jar.setCookie cookie, requestParams.url

  if clientIdCookieValue = requestParams.clientId
    cookie = request.cookie "clientId=#{clientIdCookieValue}"
    requestParams.jar ?= request.jar()
    requestParams.jar.setCookie cookie, requestParams.url

  if requestParams.body
    # after deep extending object, encodes body param to a query string
    requestParams.body = querystring.stringify requestParams.body

  if requestParams.query
    requestParams.query = querystring.stringify requestParams.query

  return requestParams


# _.extend didn't help with deep extend
# deep extending one object from another, works only for objects
deepObjectExtend = (target, source) ->

  for own prop of source

    # recursive call to deep extend
    if target[prop] and typeof source[prop] is 'object'
      deepObjectExtend target[prop], source[prop]
    # overwriting property
    else
      target[prop] = source[prop]

  return target


generateCsrfTokenCookie = (csrfToken = null) ->

  csrfToken ?= generateRandomString()
  cookie     = request.cookie "_csrf=#{csrfToken}"

  return cookie


convertToArray = (commaSeparatedData = '') ->

  return []  if commaSeparatedData is ''

  data = commaSeparatedData.split(',') or []

  data = data
    .filter (s) -> s isnt ''           # clear empty ones
    .map (s) -> s.trim().toLowerCase() # clear empty spaces

  return data


module.exports = {
  _
  hat
  async
  expect
  request
  generateUrl
  querystring
  convertToArray
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity
  generateDefaultRequestParams
  generateRequestParamsEncodeBody
}
