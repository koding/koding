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

  alreadyMember = alreadyMember is 'true'
  context       = { group: slug }
  clientId      = getClientId req, res

  # subscribe to koding marketing mailings or not
  body.emailFrequency         or= {}
  # convert string boolean to boolean
  body.emailFrequency.marketing = newsletter is 'true'
  # rename variable
  body.invitationToken          = token
  # required for JUser.login
  body.groupName                = slug

  return handleClientIdNotFound res, req  unless clientId

  client          = {}
  clientIPAddress = req.headers['x-forwarded-for'] or req.connection.remoteAddress

  queue = [

    (next) ->
      koding.fetchClient clientId, context, (client_) ->
        client = client_

        # when there is an error in the fetchClient, it returns message in it
        if client.message
          console.error JSON.stringify { req, client }
          return next { status: 500, message: client.message }

        client.clientIP = (clientIPAddress.split ',')[0]
        next()

    (next) ->
      # check if user exists
      JUser.normalizeLoginId username, (err, username_) ->
        return next { status: 500, message: getErrorMessage err }  if err

        JUser.one { username: username_ }, (err, user) ->
          if alreadyMember
            return next { status: 500, message: getErrorMessage err }  if err
            return next { status: 400, message: 'Unknown user name' }  unless user?

          alreadyMember = true  if user
          next()

  ]

  async.series queue, (err) ->
    return res.status(err.status).send getErrorMessage err  if err

    # generating callback function to be used in both login and convert
    joinTeamKallback = generateJoinTeamKallback res, body

    if alreadyMember
    then JUser.login client.sessionToken, body, joinTeamKallback
    else JUser.convert client, body, joinTeamKallback


generateJoinTeamKallback = (res, body) ->

  { Tracker } = koding.models

  # returning a callback function
  return (err, result) ->
    { redirect, slug, username } = body

    # return if we got error from join/register
    return res.status(400).send getErrorMessage err  if err?

    # login returns replacementToken but register returns newToken
    clientId = result.replacementToken or result.newToken
    # set clientId
    setSessionCookie res, clientId

    # add user to Segment group
    Tracker.group slug, username

    # handle the request with an HTTP redirect:
    return res.redirect 301, redirect if redirect

    # handle the request as an XHR response:
    return res.status(200).end()


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
