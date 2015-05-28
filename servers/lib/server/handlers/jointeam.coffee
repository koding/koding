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
    # slug is team slug, unique name. Can not be changed
    slug
    # newsletter holds announcements config.
    newsletter
    # is soon-to-be-group-member already a Koding member
    alreadyMember
    # invitation token
    token
  } = body

  alreadyMember = alreadyMember is 'true'
  context       = { group: slug }
  clientId      = getClientId req, res

  # subscribe to koding marketing mailings or not
  body.emailFrequency         or= {}
  # convert string boolean to boolean
  body.emailFrequency.marketing = newsletter is 'true'
  # rename variable
  body.invitationToken          = token

  return handleClientIdNotFound res, req  unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->

    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    kallback = (err, result) ->
      # return if we got error from join/register
      return res.status(400).send getErrorMessage err  if err?
      # set clientId
      res.cookie 'clientId', result.newToken, path : '/'

      # handle the request with an HTTP redirect:
      return res.redirect 301, redirect if redirect

      # handle the request as an XHR response:
      return res.status(200).end()

    if alreadyMember
    then JUser.login client.sessionToken, body, kallback
    else JUser.convert client, body, kallback


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
