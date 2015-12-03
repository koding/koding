{ argv }  = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")

{ daisy }                          = require 'bongo'
{ checkAuthorizationBearerHeader } = require '../../helpers'
{ sendApiError
  sendApiResponse
  checkApiAvailability }           = require './helpers'

apiErrors = require './errors'


module.exports = createSsoToken = (req, res, next) ->

  { JAccount, JGroup, JUser, JApiToken } = (require '../../bongo').models

  # validating req params
  { error, token, username } = validateRequest req
  return sendApiError res, error  if error

  account  = null
  apiToken = null

  queue = [

    ->
      # checking if token is valid
      JApiToken.one { code : token }, (err, apiToken_) ->
        return sendApiError res, apiErrors.internalError    if err
        return sendApiError res, apiErrors.invalidApiToken  unless apiToken_
        apiToken = apiToken_
        queue.next()

    ->
      checkApiAvailability { apiToken }, (err) ->
        return sendApiError res, err  if err
        queue.next()

    ->
      # checking if user exists
      JAccount.one { 'profile.nickname' : username }, (err, account_) ->
        return sendApiError res, apiErrors.internalError    if err
        return sendApiError res, apiErrors.invalidUsername  unless account_
        account = account_
        queue.next()

    ->
      # checking if user is a member of the group of api token
      client = { connection : { delegate : account } }
      account.checkGroupMembership client, apiToken.group, (err, isMember) ->
        return sendApiError res, apiErrors.internalError    if err
        return sendApiError res, apiErrors.notGroupMember   unless isMember
        queue.next()

    ->
      data    = { username, group : apiToken.group }
      options = { expiresInMinutes : 60 }
      token   = JUser.createJWT data, options

      protocol   = req.protocol
      publicPort = KONFIG.publicPort
      host       = "#{apiToken.group}.#{req.hostname}"
      URL        = "-/api/ssotoken/login?token=#{token}"
      port       = if publicPort in ['80', '443'] then '' else ":#{publicPort}"

      loginUrl = "#{protocol}://#{host}#{port}/#{URL}"
      return sendApiResponse res, { token, loginUrl }

  ]

  daisy queue



validateRequest = (req) ->

  token        = null
  { username } = req.body

  unless username
    return { error : apiErrors.invalidUsername }

  unless token = checkAuthorizationBearerHeader req
    return { error : apiErrors.unauthorizedRequest }

  return { error : null, token, username }

