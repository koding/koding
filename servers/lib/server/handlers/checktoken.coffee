koding                                  = require './../bongo'
{ getClientId, handleClientIdNotFound } = require './../helpers'

module.exports = (req, res, next) ->

  { JInvitation, JTeamInvitation, JGroup } = koding.models
  { body : { token } }                     = req

  # this is temporary and I am tired
  # let this live here please
  # until teams public launch - SY
  isTeamToken = token.length < 6

  konstructor = if isTeamToken then JTeamInvitation else JInvitation

  return res.status(400).send 'token is required'  unless token

  konstructor.byCode token, (err, token) ->
    if err
      console.error 'err while fetching token'
      return res.status(500).send 'internal server error'

    return res.status(404).send 'invitation not found'  unless token

    if token.isValid()
    then return res.status(200).send token
    else return res.status(400).send 'invitation is expired'
