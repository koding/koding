KONFIG    = require 'koding-config-manager'
async     = require 'async'

{ sendApiError
  verifyApiToken
  sendApiResponse
  checkApiAvailability }           = require './helpers'
{ checkAuthorizationBearerHeader } = require '../../helpers'

apiErrors = require './errors'


module.exports = createSsoToken = (req, res, next) ->

  { JAccount, JUser } = (require '../../bongo').models

  # validating req params
  { error, token, username } = validateRequest req
  return sendApiError res, error  if error

  account  = null
  apiToken = null

  queue = [

    (next) ->
      verifyApiToken token, (err, apiToken_) ->
        return sendApiError res, err  if err

        apiToken = apiToken_
        next()

    (next) ->
      # checking if user exists
      JAccount.one { 'profile.nickname' : username }, (err, account_) ->
        return sendApiError res, apiErrors.internalError    if err
        return sendApiError res, apiErrors.invalidUsername  unless account_
        account = account_
        next()

    (next) ->
      # checking if user is a member of the group of api token
      client = { connection : { delegate : account } }
      account.checkGroupMembership client, apiToken.group, (err, isMember) ->
        return sendApiError res, apiErrors.internalError    if err
        return sendApiError res, apiErrors.notGroupMember   unless isMember
        next()

    (next) ->
      data    = { username, group : apiToken.group }
      options = { expiresIn: '1 hour' }
      token   = JUser.createJWT data, options

      protocol   = req.protocol
      publicPort = KONFIG.publicPort
      host       = "#{apiToken.group}.#{req.hostname}"
      URL        = "-/api/ssotoken/login?token=#{token}"
      port       = if publicPort in ['80', '443'] then '' else ":#{publicPort}"

      loginUrl = "#{protocol}://#{host}#{port}/#{URL}"
      sendApiResponse res, { token, loginUrl }
      next()

  ]

  async.series queue



validateRequest = (req) ->

  token        = null
  { username } = req.body

  unless username
    return { error : apiErrors.invalidUsername }

  unless token = checkAuthorizationBearerHeader req
    return { error : apiErrors.unauthorizedRequest }

  return { error : null, token, username }
