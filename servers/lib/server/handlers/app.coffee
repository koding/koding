{ error_404, serve, serveHome, isMainDomain }   = require './../helpers'
koding                 = require './../bongo'
{ generateFakeClient } = require './../client'

module.exports = (req, res, next, options) ->

  { JName, JGroup }           = bongoModels = koding.models
  { params }                  = req
  { name, section, slug }     = params
  { path, loggedIn, account } = options
  prefix                      = if loggedIn then 'loggedIn' else 'loggedOut'

  return next()  unless isMainDomain req

  res.status(404).send error_404()  if name is 'Activity'

  generateFakeClient req, res, (err, client) ->

    serveSub = (err, subPage) ->
      return next()  if err
      serve subPage, res

    JName.fetchModels path, (err, result) ->

      if err
        o = { account, name, section, client, bongoModels, params }
        JGroup.render[prefix].subPage o, serveSub

      else if not result? then next()
      else
        { models } = result
        o = { account, name, section, models, client, bongoModels, params }

        JGroup.render[prefix].subPage o, serveSub
