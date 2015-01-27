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

    queue    = []
    response = {}

    for username in usernames
      queue.push -> JMachine.fetchByUsername username, (err, machines)->
        return err  if err

        response[username] = machines.map (machine)-> machine.data.slug
        queue.fin()

    dash queue, -> res.status(200).send response
