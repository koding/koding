koding  = require './bongo'
{
  getClientId
  handleClientIdNotFound
}       = require "./helpers"

module.exports = (req, res)->
  context   = { group: 'koding' }
  clientId  =  getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  koding.fetchClient clientId, context, (client) ->
    if client.message
      return res.status(500).send client.message

    {body} = req
    {isUserLoggedIn} = body

    # booleans are seralized as strings, so cast them back to booleans
    isUserLoggedIn = if isUserLoggedIn is "true" then true else false
    body.isUserLoggedIn = isUserLoggedIn

    {JUser} = koding.models
    JUser.authenticateWithOauth client, body, (err, result)->
      if err?
        return res.status(400).send err.message

      {replacementToken} = result
      res.cookie 'clientId', replacementToken  if replacementToken

      res.status(200).send result
