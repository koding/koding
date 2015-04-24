module.exports = (req, res) ->

  { role, sessionId } = req.body

  return res.status(400).send { err: 'Session ID is required.' } unless sessionId
  return res.status(400).send { err: 'Role is required'        } unless role

  { apiKey, apiSecret } = KONFIG.tokbox

  OpenTok = require 'opentok'

  opentok = new OpenTok apiKey, apiSecret

  token = opentok.generateToken sessionId, { role }

  return res.status(200).send { token }
