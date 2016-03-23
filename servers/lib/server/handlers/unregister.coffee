bongo = require './../bongo'
{ generateFakeClient } = require './../client'

module.exports = (req, res) ->

  generateFakeClient req, res, (err, client, session) ->
    return res.status(500).send err  if err

    { nickname } = client?.connection?.delegate?.profile
    return res.status(400).send 'nickname is not set'  unless nickname

    { JUser } = bongo.models
    JUser.unregister client, nickname, (err) ->
      return res.status(500).send err  if err

      return res.status(200).end()
