_           = require 'underscore'
hat         = require 'hat'
querystring = require 'querystring'


# deep extending one object from another, works only for objects
_.deepObjectExtend = (target, source) ->

  for prop of source

    if source.hasOwnProperty(prop)

      # recursive call to deep extend
      if target[prop] and typeof source[prop] == 'object'
        _.deepObjectExtend target[prop], source[prop]
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
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) '  +
      'AppleWebKit/537.36 (KHTML, like Gecko) '           +
      'Chrome/43.0.2357.81 Safari/537.36'

    defaultHeadersObject  =
      accept            : '*/*'
      'x-requested-with': 'XMLHttpRequest'
      'user-agent'      : userAgent
      'content-type'    : 'application/x-www-form-urlencoded; charset=UTF-8'

    return defaultHeadersObject


  @getDefaultParams = ->

    # 20 characters
    randomString         = hat().slice 12

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
    postParams        = _.deepObjectExtend defaultPostParams, opts
    # after deep extending object, encodes body param to a query string
    postParams.body   = querystring.stringify postParams.body

    return postParams


module.exports = {
  RegisterHandlerHelper
}
