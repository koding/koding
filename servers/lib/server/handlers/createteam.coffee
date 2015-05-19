Bongo                                   = require "bongo"
koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'
{ dash }                                = Bongo
{ uniq }                                = require 'underscore'

createInvitations = (client, invitees, callback)->
  return callback null  if invitees is ""

  inviteEmails = invitees.split(",") or []
  return callback null  if inviteEmails.length is 0 # return early

  # data = { invitations:[ {email:"cihangir+test26@koding.com"} ] }
  invitations =
    uniq inviteEmails                       # remove duplicates
    .filter (email) -> email isnt ""        # clear emtpty ones
    .map (email) -> { email: email.trim() } # clear empty spaces

  koding.models.JInvitation.create client, { invitations }, (err)->
    console.error "Err while creating invitations", err  if err
    callback()

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
  } = body

  redirect ?= '/'
  context   = { group: slug }
  clientId  = getClientId req, res

  # tmp: copy/paste from ./register.coffee - SY
  # cc/ @cihangir

  return handleClientIdNotFound res, req  unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->

    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify {req, client}
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    body.emailFrequency or= {}
    # subscribe to koding marketing mailings or not
    body.emailFrequency.marketing = newsletter is 'true' # convert string boolean to boolean

    JUser.convert client, body, (err, result) ->

      if err?

        {message} = err

        if err.errors?
          message = "#{message}: #{Object.keys err.errors}"

        return res.status(400).send message

      # don't set the cookie we don't want that
      # bc we're going to redirect the page to the
      # group subdomain, if you can set the cookie for
      # the subdomain - SY cc/ @cihangir

      # res.cookie 'clientId', result.newToken, path : '/'

      # set session token for later usage down the line
      client.sessionToken         = result.newToken
      owner                       = result.account
      client.connection.delegate  = result.account

      # clear domains
      allowedDomains = domains?.split(",") or []
      allowedDomains =
        uniq allowedDomains                # remove duplicates
        .filter (domain) -> domain isnt "" # clear emtpty ones
        .map (domain) -> domain.trim()     # clear empty spaces

      JGroup.create client,
        title           : companyName
        slug            : slug
        visibility      : 'hidden'
        defaultChannels : []
        initialData     : body
        allowedDomains  : allowedDomains
      , owner, (err, group) ->

        console.log err, group

        return res.status(500).send "Couldn't create the group."  if err or not group

        queue = [
          # add other parallel operations here
          -> createInvitations client, invitees, queue.fin
        ]
        dash queue, (err)->
          # do not block group creation
          console.error "Error while creating group artifacts", body, err if err

          # handle the request as an XHR response:
          return res.status(200).end() if req.xhr
          # handle the request with an HTTP redirect:
          res.redirect 301, redirect
