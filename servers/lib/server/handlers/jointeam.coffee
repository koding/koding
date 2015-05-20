Bongo                                   = require "bongo"
koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'
{ dash }                                = Bongo
{ uniq }                                = require 'underscore'

module.exports = (req, res, next) ->

  { body }                       = req
  { JUser, JGroup, JInvitation } = koding.models
  {
    redirect
    # invitation token that the user got in the mail
    token
    # slug is team slug, unique name. Can not be changed
    slug
    # newsletter holds announcements config.
    newsletter
    # is soon-to-be-group-member already a Koding member
    alreadyMember
  } = body

  alreadyMember = alreadyMember is 'true'
  context       = { group: slug }
  clientId      = getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->

    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    joinGroup = (err, result) ->

      return res.status(400).send getErrorMessage err  if err?

      res.cookie 'clientId', result.newToken, path : '/'

      # set session token for later usage down the line
      client.sessionToken         = result.newToken
      owner                       = result.account
      client.connection.delegate  = result.account

      JGroup.one { slug }, (err, group) ->

        return res.status(500).send 'Couldn\'t fetch the group.'  if err or not group

        group.join client, { as: 'member', inviteCode: token }, (err, response) ->

          return res.status(400).send getErrorMessage err  if err?

          # handle the request as an XHR response:
          return res.status(200).end() if req.xhr
          # handle the request with an HTTP redirect:
          res.redirect 301, redirect

    JInvitation.byCode token, (err, invitation) ->

      return res.status(400).send getErrorMessage err  if err?

      # subscribe to koding marketing mailings or not
      body.emailFrequency         or= {}
      body.emailFrequency.marketing = newsletter is 'true' # convert string boolean to boolean

      if alreadyMember
      then JUser.login client.sessionToken, body, joinGroup
      else JUser.convert client, body, joinGroup


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
