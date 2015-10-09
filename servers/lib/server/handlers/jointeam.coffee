Bongo                                   = require 'bongo'
koding                                  = require './../bongo'
{ uniq }                                = require 'underscore'
{ dash, daisy }                         = Bongo

{
  getClientId
  handleClientIdNotFound
  setSessionCookie
} = require './../helpers'

module.exports = (req, res, next) ->

  { body }                       = req
  { JUser, JGroup, JInvitation } = koding.models
  {
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

    ->
      koding.fetchClient clientId, context, (client_) ->
        client = client_

        # when there is an error in the fetchClient, it returns message in it
        if client.message
          console.error JSON.stringify { req, client }
          return res.status(500).send client.message

        client.clientIP = (clientIPAddress.split ',')[0]
        queue.next()

    ->
      # checking if user exists by trying to login the user
      JUser.login client.sessionToken, body, (err, result) ->
        errorMessage          = err?.message
        unknownUsernameError  = 'Unknown user name'

        # send HTTP 400 if somehow alreadyMember is true but user doesnt exist
        if alreadyMember and errorMessage is unknownUsernameError
          return res.status(400).send unknownUsernameError

        # setting alreadyMember to true if error is not unknownUsernameError
        # ignoring other errors here since our only concern is checking if user exists
        alreadyMember = errorMessage isnt unknownUsernameError
        queue.next()

    ->
      # generating callback function to be used in both login and convert
      joinTeamKallback = generateJoinTeamKallback res, body

      if alreadyMember
      then JUser.login client.sessionToken, body, joinTeamKallback
      else JUser.convert client, body, joinTeamKallback

  ]

  daisy queue


generateJoinTeamKallback = (res, body) ->

  # returning a callback function
  return (err, result) ->
    { redirect } = body

    # return if we got error from join/register
    return res.status(400).send getErrorMessage err  if err?

    # login returns replacementToken but register returns newToken
    clientId = result.replacementToken or result.newToken
    # set clientId
    setSessionCookie res, clientId

    # handle the request with an HTTP redirect:
    return res.redirect 301, redirect if redirect

    # handle the request as an XHR response:
    return res.status(200).end()


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
