_                                       = require 'underscore'
Bongo                                   = require 'bongo'
koding                                  = require './../bongo'
{ argv }                                = require 'optimist'
KONFIG                                  = require('koding-config-manager').load "main.#{argv.c}"

{ uniq }                                = require 'underscore'
{ hostname, environment }               = KONFIG
{ dash, daisy }                         = Bongo
{ getClientId, handleClientIdNotFound } = require './../helpers'

module.exports = (req, res, next) ->

  { body }                       = req
  { # slug is team slug, unique name. Can not be changed
    slug
    email
    # newsletter holds announcements config.
    newsletter
    # is group creator already a member
    alreadyMember }              = body
  { JUser, JGroup, JInvitation } = koding.models
  body.groupName                 = slug
  # needed for JUser.login to know that it is a regular login or group creation
  body.groupIsBeingCreated       = yes

  clientId                       = getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  client              = {}
  context             = { group: slug }
  client.context      = context
  clientIPAddress     = req.headers['x-forwarded-for'] || req.connection.remoteAddress
  # parsing booling from string
  alreadyMember       = alreadyMember is 'true'

  queue = [

    ->
      koding.fetchClient clientId, context, (client_) ->

        client = client_
        # when there is an error in the fetchClient, it returns message in it
        if client.message
          console.error JSON.stringify {req, client}
          return res.status(500).send client.message

        client.clientIP = (clientIPAddress.split ',')[0]

        # subscribe to koding marketing mailings or not
        body.emailFrequency         or= {}
        # convert string boolean to boolean
        body.emailFrequency.marketing = newsletter is 'true'
        queue.next()

    ->
      # checking if group slug was already used
      JGroup.one { slug }, (err, group) ->
        return res.status(500).send 'an error occured'  if err
        return res.status(403).send "Sorry,
          Team URL '#{slug}.#{hostname}' is already in use"  if group
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
      createGroupKallback = generateCreateGroupKallback client, req, res, body

      if alreadyMember
      then JUser.login client.sessionToken, body, createGroupKallback
      else JUser.convert client, body, createGroupKallback

  ]

  daisy queue


generateCreateGroupKallback = (client, req, res, body) ->

  # returning a callback function
  return (err, result) ->

    return res.status(400).send getErrorMessage err  if err?

    { # companyName, team name, basically a title, can be changed
      companyName
      # slug is team slug, unique name. Can not be changed
      slug
      redirect
      # invitees are comma separated emails which will be invited to that team
      invitees
      # domains holds allowed domains for signinup without invitation, comma separated
      domains
      # username of the user, can be already registered or a new one for creation
      username
    } = body

    token = result.newToken or result.replacementToken

    { JUser, JGroup, JInvitation } = koding.models

    # this logs you in the newly created group but causes problems
    # for the default and other subdomains
    # need to find another way - SY

    # teamDomain = switch environment
    #   when 'production'  then ".koding.com"
    #   when 'development' then ".dev.koding.com"
    #   else ".#{environment}.koding.com"

    # res.clearCookie 'clientId'
    # res.cookie 'clientId', token, path : '/', domain : teamDomain

    # set session token for later usage down the line
    owner                      = result.account
    redirect                  ?= '/'
    client.sessionToken        = token
    client.connection.delegate = result.account

    if validationError = validateGroupDataAndReturnError body
      { statusCode, errorMessage } = validationError
      return res.status(statusCode).send errorMessage

    JGroup.create client,
      slug            : slug
      title           : companyName
      visibility      : 'hidden'
      initialData     : body
      allowedDomains  : convertToArray domains # clear & convert domains into array
      defaultChannels : []
    , owner, (err, group) ->

      if err or not group
        console.error 'Error while creating the group', err
        return res.status(500).send "Couldn't create the group."

      queue = [

        # add other parallel operations here
        -> createInvitations client, invitees, (err) ->
            console.error "Err while creating invitations", err  if err
            queue.fin()

      ]

      dash queue, (err)->
        # do not block group creation
        console.error "Error while creating group artifacts", body, err if err

        # handle the request as an XHR response:
        return res.status(200).end() if req.xhr
        # handle the request with an HTTP redirect:
        res.redirect 301, redirect


validateGroupDataAndReturnError = (body) ->

  unless body.slug
    return { statusCode : 400, errorMessage : 'Group slug can not be empty.' }

  else unless body.companyName
    return { statusCode : 400, errorMessage : 'Company name can not be empty.' }

  else null

# convertToArray converts given comma separated string value into cleaned,
# trimmed, lowercased, unified array of string
convertToArray = (commaSeparatedData = '')->
  return []  if commaSeparatedData is ''

  data = commaSeparatedData.split(',') or []

  data = data
    .filter (s) -> s isnt ''           # clear empty ones
    .map (s) -> s.trim().toLowerCase() # clear empty spaces

  return uniq data # remove duplicates

# createInvitations converts given invitee list into JInvitation and creates
# them in db
createInvitations = (client, invitees, callback)->
  inviteEmails = convertToArray invitees

  return callback null  if inviteEmails.length is 0 # return early

  # should be in following structure
  #   data = { invitations:[ {email:"cihangir+test26@koding.com"} ] }
  invitations = inviteEmails.map (email) -> { email }

  koding.models.JInvitation.create client, { invitations }, callback


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
