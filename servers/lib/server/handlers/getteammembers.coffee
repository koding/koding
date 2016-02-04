Bongo                  = require 'bongo'
koding                 = require './../bongo'
async                  = require 'async'

{ isLoggedIn }         = require './../helpers'
{ generateFakeClient } = require './../client'

# handleTokenedRequest handles the request if it has a token as query param,
# fetchMembers is secured by a permission, that can be turned off by default,
# but we want to show latest members to invited user
handleTokenedRequest = (params, callback) ->

  { JGroup, JInvitation }           = koding.models
  { name, options, token, client }  = params

  group   = null
  members = null

  queue = [

    (next) ->
      return next { status: 403, message: 'not authorized' }  unless token

      # fetch invitation
      JInvitation.byCode token, (err, token_) ->
        return next { status: 403, message: 'not authorized' }  if err or not token_
        next()

    (next) ->
      # fetch the group that we have in token
      JGroup.one { slug : name }, (err, group_) ->
        return next { status: 500, message: 'an error occured' }  if err
        return next { status: 404, message: 'no group found' }    unless group_

        group = group_
        # override group name with the one in token
        client.context.group = group.slug
        next()

    (next) ->
      # fetch members of that group
      group.fetchMembers {}, options, (err, members_) ->
        return next { status: 500, message: 'an error occured' }  if err
        members = members_
        next()

  ]

  async.series queue, (err) ->
    return callback err  if err
    callback null, members


# fetch last members of a group, if we have a permission issue for the current
# user, try to fetch it with token
module.exports = (req, res, next) ->

  { params, query } = req
  { name }          = params
  { limit, token }  = query
  { JGroup }        = koding.models

  group   = null
  client  = null
  members = null

  queue = [

    (next) ->
      isLoggedIn req, res, (err, loggedIn, account) ->
        return next { status: 500, message: 'an error occured' }  if err
        next()

    (next) ->
      JGroup.one { slug : name }, (err, group_) ->
        return next { status: 500, message: 'an error occured' }  if err
        return next { status: 404, message: 'no group found' }    unless group_
        group = group_
        next()

    (next) ->
      generateFakeClient req, res, (err, client_) ->
        return next { status: 500, message: 'an error occured' }  if err
        client = client_
        next()

    (next) ->
      options       = {}
      options.sort  = { 'meta.createdAt' : -1 }
      options.limit = Math.min limit ? 10, 25

      group.fetchMembers$ client, {}, options, (err, members_) ->

        if err and err.message is 'Access denied'
          params = { name, client, options, token }
          handleTokenedRequest params, (err, members_) ->
            return next err  if err
            members = members_
            return next()
        else if err
          return next { status: 500, message: 'an error occured' }
        else
          members = members_
          return next()

  ]

  async.series queue, (err) ->
    return res.status(err.status).send err.message  if err
    res.status(200).send members
