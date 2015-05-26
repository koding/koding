Bongo                                   = require "bongo"
koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'
{ dash }                                = Bongo
{ uniq }                                = require 'underscore'

module.exports = (req, res, next) ->

  { body }                       = req
  { JUser, JGroup, JInvitation } = koding.models
  { # companyName, team name, basically a title, can be changed
    companyName
    # slug is team slug, unique name. Can not be changed
    slug
    redirect
    # invitees are comma separated emails which will be invited to that team
    invitees
    # domains holds allowed domains for signinup without invitation, comma separated
    domains
    # newsletter holds announcements config.
    newsletter
    # is group creator already a member
    alreadyMember
  } = body

  redirect ?= '/'
  context   = { group: slug }
  clientId  = getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->

    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    # subscribe to koding marketing mailings or not
    body.emailFrequency         or= {}
    body.emailFrequency.marketing = newsletter is 'true' # convert string boolean to boolean

    createGroup = (err, result) ->

      return res.status(400).send getErrorMessage err  if err?

      # don't set the cookie we don't want that
      # bc we're going to redirect the page to the
      # group subdomain, if you can set the cookie for
      # the subdomain - SY cc/ @cihangir

      # res.cookie 'clientId', result.newToken, path : '/'

      # set session token for later usage down the line
      client.sessionToken         = result.newToken
      owner                       = result.account
      client.connection.delegate  = result.account

      JGroup.create client,
        title           : companyName
        slug            : slug
        visibility      : 'hidden'
        defaultChannels : []
        initialData     : body
        allowedDomains  : convertToArray domains # clear & convert domains into array
      , owner, (err, group) ->

        return res.status(500).send "Couldn't create the group."  if err or not group

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

    if alreadyMember is 'true'
    then JUser.login client.sessionToken, body, createGroup
    else JUser.convert client, body, createGroup



# convertToArray converts given comma separated string value into cleaned,
# trimmed, lowercased, unified array of string
convertToArray = (commaSeparatedData)->
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
