{ serve, serveHome }   = require './../helpers'
koding                 = require './../bongo'
{ generateFakeClient } = require "./../client"
Crawler                = require './../../crawler'

module.exports = (req, res, next, options)->

  { JName, JGroup }           = bongoModels = koding.models
  { params }                  = req
  { name, section, slug }     = params
  { path, loggedIn, account } = options
  prefix                      = if loggedIn then 'loggedIn' else 'loggedOut'

  if name is 'Activity'
    # When we try to access /Activity/Message/New route, it is trying to
    # fetch message history with channel id = 'New' and returning:
    # Bad Request: strconv.ParseInt: parsing "New": invalid syntax error.
    # Did not like the way I resolve this, but this handler function is already
    # saying 'Refactor me' :) - CtF
    return next()                    if section is 'Message' and slug is 'New'
    return serveHome req, res, next  if loggedIn

    return Crawler.crawl koding, { req, res, slug : path }

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
