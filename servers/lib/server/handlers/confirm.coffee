{argv}    = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
{secret}  = KONFIG.jwt

Analytics = require '../../../../workers/social/lib/social/models/analytics.coffee'
Jwt       = require 'jsonwebtoken'

module.exports = (req, res, next) ->

  {JUser, JSession} = (require './../bongo').models

  logErrorAndReturn = (err) ->
    console.error 'confirm handler failed:', err
    res.status(500).end()

  {token, redirect_uri} = req.query

  unless token
    return res.status(400).end()

  Jwt.verify token, secret, algorithms: ['HS256'], (err, decoded) ->
    return logErrorAndReturn err  if err

    unless username = decoded.username
      return logErrorAndReturn 'no username in token'

    JUser.one {username}, (err, user) ->
      return logErrorAndReturn err  if err

      user.confirmEmail (err) ->
        return logErrorAndReturn err  if err

        groupName = 'koding'
        JSession.createNewSession {username, groupName}, (err, session) ->
          return logErrorAndReturn err  if err

          res.cookie 'clientId', session.clientId, path: '/'
          res.redirect redirect_uri or '/'

          Analytics.track username, 'confirmed & logged in using token'
