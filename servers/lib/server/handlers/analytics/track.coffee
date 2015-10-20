bongo  = require '../../bongo'
client = require '../../client'

{ generateFakeClient } = client

module.exports = (req, res) ->

  { Tracker } = bongo.models

  { action, properties } = req.body

  unless action
    return res.status(400).send 'Missing action'

  generateFakeClient req, res, (err, client, session) ->
    return res.status(500).send err  if err

    event = { subject: action }

    Tracker.track session.username, event, properties
    res.status(200).end()
