bongo  = require '../../bongo'
client = require '../../client'

{ generateFakeClient } = client

module.exports = (req, res) ->

  { Tracker } = bongo.models

  { name, category, properties } = req.body

  unless name
    return res.status(400).send 'Missing page name'

  generateFakeClient req, res, (err, client, session) ->
    return res.status(500).send err  if err

    Tracker.page session.username, name, category, properties
    res.status(200).end()
