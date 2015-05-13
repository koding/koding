koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'

module.exports = (req, res, next) ->

  { body }                        = req
  { JUser, JGroup }               = koding.models
  { companyName, slug, redirect } = body

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

    JUser.convert client, req.body, (err, result) ->

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
      client.sessionToken = result.newToken
      owner               = result.account

      JGroup.create client,
        title           : companyName
        slug            : slug
        visibility      : 'hidden'
        defaultChannels : []
        initialData     : body
      , owner, (err, group) ->

        console.log err, group

        return res.status(500).send "Couldn't create the group."  if err or not group

        # handle the request as an XHR response:
        return res.status(200).end() if req.xhr
        # handle the request with an HTTP redirect:
        res.redirect 301, redirect
