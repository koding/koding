{ get } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

{ dash } = require 'bongo'

module.exports = (req, res) ->
  koding     = require './bongo'
  {JMachine} = koding.models

  errMsg = (msg)->
    {
      "description" : msg
      "error"       : "bad_request"
    }

  {key} = req.query

  unless key
    return res.status(401).send errMsg "key is required"

  # Hardcoding is wrong, however this key won't change
  # depending on environments, so there's point of
  # putting it in config : SA
  unless key is "R1PVxSPvjvDSWdlPRVqRv8IdwXZB"
    return res.status(401).send errMsg "key is wrong"

  url = "/payments/customers"

  get url, {}, (err, usernames)->
    return res.status(400).send err  if err

    response = {}
    username = usernames[Math.floor((Math.random() * usernames.length))]

    JMachine.fetchByUsername username, (err, machines)->
      return res.status(500).send err  if err

      slugs = []
      machines.forEach (machine)->
        slugs.push  machine.data.slug  if machine.data.meta.alwaysOn

      res.status(200).send { "username" : username, "vms" : slugs }
