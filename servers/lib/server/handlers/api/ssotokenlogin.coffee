async      = require 'async'
apiErrors  = require './errors'

{ setSessionCookie } = require '../../helpers'
{ sendApiError
  validateJWTToken
  sendApiResponse }  = require './helpers'

module.exports = ssoTokenLogin = (req, res, next) ->

  { JUser, JSession, JAccount } = (require '../../bongo').models

  { token } = req.query
  user      = null
  group     = null
  session   = null
  account   = null
  username  = null

  return sendApiError res, apiErrors.missingRequiredQueryParameter  unless token

  queue = [

    (next) ->
      validateJWTToken token, (err, data) ->
        return next err  if err
        { username, group } = data

        # making sure subdomain is same with group slug
        unless group in req.subdomains
          return next apiErrors.invalidRequestDomain

        next()

    (next) ->
      # checking if user exists
      JAccount.one { 'profile.nickname' : username }, (err, account_) ->
        return next apiErrors.internalError    if err
        return next apiErrors.invalidUsername  unless account_
        account = account_
        next()

    (next) ->
      # checking if user is a member of the group of api token
      client = { connection : { delegate : account } }
      account.checkGroupMembership client, group, (err, isMember) ->
        return next apiErrors.internalError   if err
        return next apiErrors.notGroupMember  unless isMember
        next()

    (next) ->
      # creating a user session for the group if everything is ok
      JSession.createNewSession { username, groupName : group }, (err, session_) ->
        return next apiErrors.internalError           if err
        return next apiErrors.failedToCreateSession   unless session_
        session = session_
        next()

  ]

  async.series queue, (err) ->
    return sendApiError res, err  if err

    setSessionCookie res, session.clientId
    res.redirect('/')
