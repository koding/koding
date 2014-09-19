{ post } = require (
  "../../../workers/social/lib/social/models/socialapi/request"
)

module.exports = (req, res) ->
  url = "/payments/stripe/webhook"
  post url, data, callback

  res.send 200
