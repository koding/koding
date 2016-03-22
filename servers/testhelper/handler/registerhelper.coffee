{ expect
  request
  querystring
  generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateRegisterRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf             : generateRandomString()
    email             : generateRandomEmail()
    agree             : 'on'
    username          : generateRandomUsername()
    password          : 'testpass'
    inviteCode        : ''
    passwordConfirm   : 'testpass'

  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


# overwrites given options in the default params
generateRegisterRequestParams = (opts = {}) ->

  body = generateRegisterRequestBody()

  params =
    url        : generateUrl { route : 'Register' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


withRegisteredUser = (opts, callback) ->

  [opts, callback]      = [callback, opts]  unless callback
  opts                 ?= {}
  opts.body             = generateRegisterRequestBody opts.body
  opts.csrfCookie       = opts.body?._csrf
  registerRequestParams = generateRegisterRequestParams opts

  request.post registerRequestParams, (err, res, body) ->
    expect(err).to.not.exist
    expect(res.statusCode).to.be.equal 200
    expect(body).to.be.empty

    extraParams = { headers: res.headers }
    callback opts.body, extraParams


module.exports = {
  withRegisteredUser
  generateRegisterRequestBody
  generateRegisterRequestParams
}
