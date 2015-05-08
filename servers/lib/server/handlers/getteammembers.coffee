koding                 = require './../bongo'
{ isLoggedIn }         = require './../helpers'
{ generateFakeClient } = require "./../client"

module.exports = (req, res, next) ->

  { params, query } = req
  { name }          = params
  { limit }         = query
  { JGroup }        = koding.models

  isLoggedIn req, res, (err, loggedIn, account) ->

    return res.status(500).send 'an error occured'  if err

    JGroup.one slug : name, (err, group) ->

      return res.status(500).send 'an error occured'  if err
      return res.status(404).send 'no group found'    unless group

      generateFakeClient req, res, (err, client) ->

        return res.status(500).send 'an error occured'  if err

        options       = {}
        options.sort  = 'meta.createdAt' : -1
        options.limit = Math.min limit ? 10, 25

        group.fetchMembers$ client, {}, options, (err, members) ->

          return res.status(403).send 'not authorized'    if err and err.name is 'AccessDenied'
          return res.status(500).send 'an error occured'  if err
          return res.status(200).send members
