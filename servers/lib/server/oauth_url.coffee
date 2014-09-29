koding  = require './bongo'
{
  getClientId
  handleClientIdNotFound
}       = require "./helpers"

module.exports = (req, res)->
  context   = { group: 'koding' }
  clientId  = getClientId req, res

  return handleClientIdNotFound res, req  unless clientId

  {provider} = req.query

  unless provider
    return res.send 400, {"message" : "provider is required"}

  if provider isnt "github"
    return res.send 400, {"message" : "only 'github' is supported via xhr"}

  koding.fetchClient clientId, context, (client) ->
    if client.message
      return res.send 500, client.message

    {OAuth} = koding.models
    OAuth.getUrl client, provider, (err, url)->
      return res.send 400, err.message  if err
      res.send 200, url
