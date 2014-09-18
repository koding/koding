{ bareRequest } = require (
  "../../../workers/social/lib/social/models/socialapi/helper"
)

module.exports = (req, res) ->
  bareRequest "stripeWebhook", req.body, ->
  res.send 200
