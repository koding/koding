videoSessions = {}
module.exports = (req, res) ->

  { channelId } = req.body

  return res.status(400).send { err: 'Channel ID is required.'      }  unless channelId
  return res.status(200).send { sessionId: videoSessions[channelId] }  if videoSessions[channelId]

  { apiKey, apiSecret } = KONFIG.tokbox

  OpenTok = require 'opentok'

  opentok = new OpenTok apiKey, apiSecret

  opentok.createSession (err, session) ->

    videoSessions[channelId] = session.sessionId

    res.status(200).send { sessionId: session.sessionId }
