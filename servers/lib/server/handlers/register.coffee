{ getClientId
  handleClientIdNotFound
  setSessionCookie
} = require './../helpers'
koding                     = require './../bongo'

module.exports = (req, res) ->

  { JUser }              = koding.models
  { redirect }           = req.body
  redirect              ?= '/'
  context                = { group: 'koding' }
  clientId               = getClientId req, res
  body                   = req.body
  body.invitationToken   = body.token

  return handleClientIdNotFound res, req unless clientId

  clientIPAddress = req.headers['x-forwarded-for'] or req.connection.remoteAddress

  koding.fetchClient clientId, context, (client) ->
    # when there is an error in the fetchClient, it returns message in it
    if client.message
      console.error JSON.stringify { req, client }
      return res.status(500).send client.message

    client.clientIP = (clientIPAddress.split ',')[0]

    JUser.convert client, body, (err, result) ->

      if err?

        { message } = err

        if err.errors?
          message = "#{message}: #{Object.keys err.errors}"

        return res.status(400).send message

      setSessionCookie res, result.newToken

      # handle the request as an XHR response:
      return res.status(200).end() if req.xhr
      # handle the request with an HTTP redirect:
      res.redirect 301, redirect
