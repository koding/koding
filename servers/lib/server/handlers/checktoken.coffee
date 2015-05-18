koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'

module.exports = (req, res, next) ->

  { body }                = req
  { JInvitation, JGroup } = koding.models
  { token }               = body

  return res.status(400).send 'token is required'  unless token

  JInvitation.byCode token, (err, data) ->
    if err
      console.error 'err while fetching token'
      return res.status(500).send 'internal server error'

    return res.status(404).send 'invitation not found'  unless data
    return res.status(200).send data
