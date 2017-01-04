koding = require '../bongo'
KONFIG  = require 'koding-config-manager'
{ generateFakeClient }   = require '../client'
{ serveHome, isLoggedIn, isTeamPage } = require './../helpers'

module.exports = (req, res, next) ->
  { JGroup } = bongoModels = koding.models

  generateFakeClient req, res, (err, client, session) ->
    return next() if err or not client

    isLoggedIn req, res, (err, isLoggedIn, account) ->
      if err
        res.status(500).send error_500()
        return console.error err

      # construct options
      client.connection.delegate = account
      { params }                 = req
      { loggedIn, loggedOut }    = JGroup.render
      fn                         = if isLoggedIn then loggedIn else loggedOut
      options                    = { client, account, bongoModels, params, session }

      serveKodingHome = ->
        fn.kodingHome options, (err, subPage) ->
          return next()  if err
          return serve subPage, res

      return serveKodingHome() if req.path isnt '/'

      # main path has a special case where all users should be redirected to
      # hubspot

      # if incoming request goes to a team page, should resolve immediately -
      # without a redirection requirement
      if isTeamPage(req)
        return serveKodingHome() if isLoggedIn

        return res.redirect 307, '/Login'

      # but if we are in dev or sandbox env, serve content as we used to
      if KONFIG.environment in ['dev', 'default', 'sandbox']
        return serveKodingHome()  if isLoggedIn

        return res.redirect 307, '/Teams'

      # all other requests coming to slash, goes back to KONFIG.marketingPagesURL
      return res.redirect 307, KONFIG.marketingPagesURL


serve = (content, res) ->
  res.header 'Content-type', 'text/html'
  res.send content
