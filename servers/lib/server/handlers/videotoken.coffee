{ findUsernameFromSession } = require '../helpers'

module.exports = (req, res) ->

  { role, sessionId } = req.body

  return res.status(400).send { err: 'Session ID is required.' }  unless sessionId
  return res.status(400).send { err: 'Role is required'        }  unless role

  { apiKey, apiSecret } = KONFIG.tokbox

  OpenTok = require 'opentok'

  opentok = new OpenTok apiKey, apiSecret

  findUsernameFromSession req, res, (err, username) ->
    return res.status(400).send { err: 'Error while looking for username' }  if err

    # this is data to be passed to other clients, we are sending username
    # here so that other clients getting the `connectionCreated` events
    # can identify who is that connection coming from.
    data    = { nickname: username }
    options = { role, data: JSON.stringify data }
    token   = opentok.generateToken sessionId, options

    res.status(200).send { token }

