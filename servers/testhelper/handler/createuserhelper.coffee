{ expect
  request
  generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateCreateUserRequestBody = (opts = {}) ->

  defaultBodyObject =
    email             : generateRandomEmail()
    username          : generateRandomUsername()
    lastName          : generateRandomString()
    firstName         : generateRandomString()
    suggestedUsername : ''

  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateCreateUserRequestParams = (opts = {}) ->

  params =
    url     : generateUrl { route : '-/api/user/create' }
    body    : generateCreateUserRequestBody()
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


createUser = (apiToken, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  opts ?= {}

  createUserRequestBody   = generateCreateUserRequestBody opts
  createUserRequestParams = generateCreateUserRequestParams
    body    : createUserRequestBody
    headers : { Authorization : "Bearer #{apiToken}" }

  request.post createUserRequestParams, (err, res, body) ->
    expect(err).to.not.exist
    expect(res.statusCode).to.be.equal 200
    callback createUserRequestBody


module.exports = {
  createUser
  generateCreateUserRequestParams
}
