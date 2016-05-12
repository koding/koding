KONFIG     = require 'koding-config-manager'
{ secret } = KONFIG.jwt

Tracker = require '../../../../workers/social/lib/social/models/tracker.coffee'
Jwt     = require 'jsonwebtoken'

{ setSessionCookie } = require '../helpers'

module.exports = (req, res, next) ->

  { JUser, JSession } = (require './../bongo').models

  logErrorAndReturn = (err) ->
    console.error 'confirm handler failed:', err
    res.status(500).end()

  { token, redirect_uri } = req.query

  unless token
    return res.status(400).end()

  Jwt.verify token, secret, { algorithms: ['HS256'] }, (err, decoded) ->
    return logErrorAndReturn err  if err

    unless username = decoded.username
      return logErrorAndReturn 'no username in token'

    groupName = decoded.groupName or 'koding'

    JUser.one { username }, (err, user) ->
      return logErrorAndReturn err  if err
      return logErrorAndReturn 'User not found'  unless user

      user.confirmEmail (err) ->
        return logErrorAndReturn err  if err

        JSession.createNewSession { username, groupName }, (err, session) ->
          return logErrorAndReturn err  if err

          setSessionCookie res, session.clientId
          res.redirect redirect_uri or '/'

          Tracker.track username, { subject : Tracker.types.CONFIRM_USING_TOKEN }
