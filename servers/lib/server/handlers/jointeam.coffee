Bongo                                   = require 'bongo'
koding                                  = require './../bongo'
{ uniq }                                = require 'underscore'
async                                   = require 'async'

{
  getClientId
  handleClientIdNotFound
  setSessionCookie
} = require './../helpers'

module.exports = (req, res, next) ->

  { body }                       = req
  { JUser, JGroup, JInvitation } = koding.models
  {
    username
    # slug is team slug, unique name. Can not be changed
    slug
    # newsletter holds announcements config.
    newsletter
    # is soon-to-be-group-member already a Koding member
    alreadyMember
    # invitation token
    token
  } = body

  clientId = getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  # subscribe to koding marketing mailings or not
  body.emailFrequency or= {}
  # convert string boolean to boolean
  body.emailFrequency.marketing = newsletter is 'true'
  # rename variable
  body.invitationToken = token
  # required for JUser.login
  body.groupName = slug
  # clients can send data about membership, convert/joinuser will use this for
  # extra validation.
  body.alreadyMember = alreadyMember is 'true'

  clientIPAddress = req.headers['x-forwarded-for'] or req.connection.remoteAddress

  koding.fetchClient clientId, context = { group: slug }, (client) ->

    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify { req, client }
      return res.status(500).send { message: client.message }

    client.clientIP = (clientIPAddress.split ',')[0]

    JGroup.joinUser client, body, generateJoinTeamKallback res, body


generateJoinTeamKallback = (res, body) ->

  { Tracker } = koding.models

  # returning a callback function
  return (err, result) ->
    { redirect, slug, username } = body

    # return if we got error from join/register
    return res.status(400).send getErrorMessage err  if err?

    { token: clientId } = result

    # set clientId
    setSessionCookie res, clientId

    # add user to Segment group
    Tracker.group slug, username

    # handle the request with an HTTP redirect:
    return res.redirect 301, redirect  if redirect

    # handle the request as an XHR response:
    return res.status(200).end()


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
