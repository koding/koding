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
    return res.status(400).send({"message" : "provider is required"})

  if provider isnt "github"
    return res.status(400).send({
      "message" : "only 'github' is supported via xhr"
    })

  koding.fetchClient clientId, context, (client) ->
    if client.message
      return res.status(500).send client.message

    {OAuth} = koding.models
    OAuth.getUrl client, provider, (err, url)->
      return res.status(400).send err.message  if err
      res.status(200).send url
