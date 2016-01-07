{ expect
  request
  generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'
{ createUser }                      = require './createuserhelper'


generateCreateSsoTokenRequestBody = (opts = {}) ->

  defaultBodyObject = { username : generateRandomUsername() }
  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateCreateSsoTokenRequestParams = (opts = {}) ->

  params =
    url     : generateUrl { route : '-/api/ssotoken/create' }
    body    : generateCreateSsoTokenRequestBody()
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


createSsoToken = (apiToken, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  opts ?= {}

  createSsoTokenRequestBody   = generateCreateSsoTokenRequestBody opts
  createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
    body    : createSsoTokenRequestBody
    headers : { Authorization : "Bearer #{apiToken}" }

  request.post createSsoTokenRequestParams, (err, res, body) ->
    expect(err).to.not.exist
    expect(res.statusCode).to.be.equal 200
    expect(JSON.parse(body).error).to.not.exist
    expect(JSON.parse(body).data).to.exist
    return callback { token : JSON.parse(body).data.token }


createUserAndSsoToken = (apiToken, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  opts ?= {}

  createUser apiToken, opts, ({ username, email }) ->
    opts.username = username
    createSsoToken apiToken, opts, ({ token }) ->
      callback { username, email, token }


module.exports = {
  createUserAndSsoToken
  generateCreateSsoTokenRequestParams
}
