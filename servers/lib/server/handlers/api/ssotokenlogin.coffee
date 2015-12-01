{ daisy }  = require 'bongo'
{ argv }   = require 'optimist'
KONFIG     = require('koding-config-manager').load("main.#{argv.c}")
{ secret } = KONFIG.jwt
Jwt        = require 'jsonwebtoken'
hat        = require 'hat'
apiErrors  = require './errors'

{ setSessionCookie }          = require '../../helpers'
{ sendApiError
  sendApiResponse
  checkApiTokenAvailability } = require './helpers'

module.exports = ssoTokenLogin = (req, res, next) ->

  { JUser, JSession, JAccount } = (require '../../bongo').models

  { token } = req.query
  user      = null
  group     = null
  account   = null
  username  = null

  return sendApiError res, apiErrors.missingRequiredQueryParameter  unless token

  queue = [

    ->
      validateToken token, (err, data) ->
        return sendApiError res, err  if err
        { username, group } = data

        # making sure subdomain is same with group slug
        unless group in req.subdomains
          return sendApiError res, apiErrors.invalidRequest

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
      account.checkGroupMembership client, group, (err, isMember) ->
        return sendApiError res, apiErrors.internalError   if err
        return sendApiError res, apiErrors.notGroupMember  unless isMember
        queue.next()

    ->
      # creating a user session for the group if everything is ok
      JSession.createNewSession { username, groupName : group }, (err, session) ->
        return sendApiError res, apiErrors.internalError           if err
        return sendApiError res, apiErrors.failedToCreateSession   unless session

        setSessionCookie res, session.clientId
        res.redirect('/')

  ]

  daisy queue


validateToken = (token, callback) ->

  Jwt.verify token, secret, { algorithms: ['HS256'] }, (err, decoded) ->
    { username, group } = decoded

    return callback apiErrors.ssoTokenFailedToParse   if err
    return callback apiErrors.invalidSSOTokenPayload  unless username
    return callback apiErrors.invalidSSOTokenPayload  unless group
    return callback null, { username, group }

