koding                   = require './../bongo'
{ isLoggedIn }           = require './../helpers'
{ generateFakeClient }   = require "./../client"

# handleTokenedRequest handles the request if it has a token as query param,
# fetchMembers is secured by a permission, that can be turned off by default,
# but we want to show latest members to invited user
handleTokenedRequest = (params, res, next) ->
  { JInvitation } = koding.models
  { options, token, client } = params

  return res.status(403).send 'not authorized'  unless token

  # fetch invitation
  JInvitation.byCode token, (err, token_) ->
    if err or not token_
      return res.status(403).send 'not authorized'
    else
      # fetch the group that we have in token
      JGroup.one slug : name, (err, group) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(404).send 'no group found'    unless group

        # override group name with the one in token
        client.context.group = group.slug

        # fetch members of that group
        group.fetchMembers {}, options, (err, members) ->
          if err
            return res.status(500).send 'an error occured'
          else
            return res.status(200).send members

# fetch last members of a group, if we have a permission issue for the current
# user, try to fetch it with token
module.exports = (req, res, next) ->
  { params, query } = req
  { name }          = params
  { limit, token }  = query
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
          if err and err.message is 'AccessDenied'
            return handleTokenedRequest { client, options, token }, res, next
          else if err
            return res.status(500).send 'an error occured'
          else
            return res.status(200).send members
