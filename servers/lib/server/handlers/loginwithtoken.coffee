Jwt = require 'jsonwebtoken'
async = require 'async'
KONFIG = require 'koding-config-manager'
{ secret } = KONFIG.jwt
{ setSessionCookie } = require '../helpers'

module.exports = (req, res, next) ->

  { JUser, JSession, JAccount } = (require './../bongo').models

  { token, redirectTo } = req.query

  return res.status(400).send 'Token is not set'   if not token

  queue = [
    (next) -> Jwt.verify token, secret, { algorithms: ['HS256'] }, next

    (decoded, next) ->
      unless username = decoded.username
        return next 'no username in token'

      unless groupName = decoded.groupName
        return next 'no groupName in token'

      return next null, username, groupName

    (username, groupName, next) ->
      JAccount.one { 'profile.nickname': username }, ( err, account ) ->
        return next err  if err
        return next 'Account not found' if not account

        return next null, account, groupName

    (account, groupName, next) ->
      JAccount.checkGroupMembership account, groupName, (err, member) ->
        return next err  if err
        return next 'Account is not a member of the group' if not member

        return next null, account, groupName

    (account, groupName, next) ->
      data = { username: account.profile.nickname, groupName }

      JSession.createNewSession data, next
  ]

  async.waterfall queue, (err, session) ->
    return res.status(400).send err.message or err  if err
    return res.status(400).send 'session is not valid'  if not session


    setSessionCookie res, session.clientId

    res.redirect redirectTo or '/'
