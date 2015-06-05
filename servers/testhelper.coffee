_           = require 'underscore'
hat         = require 'hat'
querystring = require 'querystring'


# returns 20 characters by default
getRandomString  = (length = 20) ->

  return hat().slice(32 - length)


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

  @getDefaultBodyObject = (randomString) ->

    defaultBodyObject     =
      email             : "testuser+#{randomString}@koding.com"
      password          : 'testtest'
      inviteCode        : ''
      username          : randomString
      passwordConfirm   : 'testtest'
      agree             : 'on'

    return defaultBodyObject


  @getDefaultHeadersObject = ->

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


  @getDefaultParams = ->

    randomString         = getRandomString()

    defaultBodyObject    = RegisterHandlerHelper.getDefaultBodyObject randomString

    defaultHeadersObject = RegisterHandlerHelper.getDefaultHeadersObject()

    defaultParams        =
      url               : 'http://localhost:8090/Register'
      body              : defaultBodyObject
      headers           : defaultHeadersObject

    return defaultParams


  # overwrites given options in the default params
  @getPostParams = (opts = {}) ->

    defaultPostParams = RegisterHandlerHelper.getDefaultParams()
    postParams        = deepObjectExtend defaultPostParams, opts
    # after deep extending object, encodes body param to a query string
    postParams.body   = querystring.stringify postParams.body

    return postParams


module.exports = {
  RegisterHandlerHelper
  getRandomString
}
