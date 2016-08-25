koding  = require './bongo'
{
  getClientId
  handleClientIdNotFound
  setSessionCookie
}       = require './helpers'

module.exports = (req, res) ->
  context   = { group: 'koding' }
  clientId  =  getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  koding.fetchClient clientId, context, (client) ->
    if client.message
      return res.status(500).send client.message

    { body }           = req
    { isUserLoggedIn } = body

    isUserLoggedIn      = isUserLoggedIn is 'true'
    body.isUserLoggedIn = isUserLoggedIn

    { JUser } = koding.models
    JUser.authenticateWithOauth client, body, (err, result) ->
      if err?
        return res.status(400).send err.message

      { replacementToken } = result

      setSessionCookie res, replacementToken  if replacementToken

      res.status(200).send result
