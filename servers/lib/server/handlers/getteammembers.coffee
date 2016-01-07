Bongo                  = require 'bongo'
koding                 = require './../bongo'

{ daisy }              = Bongo
{ isLoggedIn }         = require './../helpers'
{ generateFakeClient } = require './../client'

# handleTokenedRequest handles the request if it has a token as query param,
# fetchMembers is secured by a permission, that can be turned off by default,
# but we want to show latest members to invited user
handleTokenedRequest = (params, res, next) ->

  { JGroup, JInvitation }           = koding.models
  { name, options, token, client }  = params

  group = null

  queue = [

    ->
      return res.status(403).send 'not authorized'  unless token

      # fetch invitation
      JInvitation.byCode token, (err, token_) ->
        return res.status(403).send 'not authorized'  if err or not token_
        queue.next()

    ->
      # fetch the group that we have in token
      JGroup.one { slug : name }, (err, group_) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(404).send 'no group found'    unless group_

        group = group_
        # override group name with the one in token
        client.context.group = group.slug
        queue.next()

    ->
      # fetch members of that group
      group.fetchMembers {}, options, (err, members) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(200).send members

  ]

  daisy queue


# fetch last members of a group, if we have a permission issue for the current
# user, try to fetch it with token
module.exports = (req, res, next) ->

  { params, query } = req
  { name }          = params
  { limit, token }  = query
  { JGroup }        = koding.models

  group  = null
  client = null

  queue = [

    ->
      isLoggedIn req, res, (err, loggedIn, account) ->
        return res.status(500).send 'an error occured'  if err
        queue.next()

    ->
      JGroup.one { slug : name }, (err, group_) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(404).send 'no group found'    unless group_
        group = group_
        queue.next()

    ->
      generateFakeClient req, res, (err, client_) ->
        return res.status(500).send 'an error occured'  if err
        client = client_
        queue.next()

    ->
      options       = {}
      options.sort  = { 'meta.createdAt' : -1 }
      options.limit = Math.min limit ? 10, 25

      group.fetchMembers$ client, {}, options, (err, members) ->

        if err and err.message is 'Access denied'
          params = { name, client, options, token }
          return handleTokenedRequest params, res, next
        else if err
          return res.status(500).send 'an error occured'
        else
          return res.status(200).send members

  ]

  daisy queue
