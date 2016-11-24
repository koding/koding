{ error_404, isMainDomain } = require './../helpers'

koding                 = require './../bongo'
{ generateFakeClient } = require './../client'

module.exports = (req, res, next, options) ->

  bongoModels                 = koding.models
  { JName }                   = bongoModels
  { params }                  = req
  { name, section, slug }     = params
  { path, loggedIn, account } = options

  return next()  unless isMainDomain req

  JName.fetchModels name, (err, result) ->

    return next err  if err
    return res.status(404).send error_404()  unless result?
    return res.status(404).send error_404()  unless loggedIn
    return next()  unless result.models.last?

    model = result.models.last

    generateFakeClient req, res, (err, client, session) ->

      model.fetchHomepageView {
        section, account, bongoModels,
        client, params, loggedIn, session
      }, (err, view) ->
        if err then next err
        else if view? then res.send view
        else res.status(404).send error_404()
