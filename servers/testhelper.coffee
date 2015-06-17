_           = require 'underscore'
hat         = require 'hat'
querystring = require 'querystring'


# returns 20 characters by default
generateRandomString = (length = 20) ->

  return hat().slice(32 - length)

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


class RegisterHandlerHelper

  @generateDefaultBodyObject = (randomString) ->

    defaultBodyObject     =
      email             : "testuser+#{randomString}@koding.com"
      password          : 'testpass'
      inviteCode        : ''
      username          : randomString
      passwordConfirm   : 'testpass'
      agree             : 'on'

    return defaultBodyObject


  @generateDefaultHeadersObject = ->

    userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3)
      AppleWebKit/537.36 (KHTML, like Gecko)
      Chrome/43.0.2357.81 Safari/537.36'

    defaultHeadersObject  =
      accept            : '*/*'
      'x-requested-with': 'XMLHttpRequest'
      'user-agent'      : userAgent
      'content-type'    : 'application/x-www-form-urlencoded; charset=UTF-8'

    return defaultHeadersObject


  @generateDefaultParams = ->

    randomString         = generateRandomString()

    defaultBodyObject    = RegisterHandlerHelper.generateDefaultBodyObject randomString

    defaultHeadersObject = RegisterHandlerHelper.generateDefaultHeadersObject()

    defaultParams        =
      url               : 'http://localhost:8090/Register'
      body              : defaultBodyObject
      headers           : defaultHeadersObject

    return defaultParams


  # overwrites given options in the default params
  @generatePostParams = (opts = {}) ->

    defaultPostParams = RegisterHandlerHelper.generateDefaultParams()
    postParams        = deepObjectExtend defaultPostParams, opts
    # after deep extending object, encodes body param to a query string
    postParams.body   = querystring.stringify postParams.body

    return postParams


module.exports = {
  RegisterHandlerHelper
  generateRandomString
}
