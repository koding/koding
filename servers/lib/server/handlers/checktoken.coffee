koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'

module.exports = (req, res, next) ->

  { body }   = req
  { JGroup } = koding.models
  { token }  = body

  console.log token

  res.status(200).send email : 'invitee@foo.com'
