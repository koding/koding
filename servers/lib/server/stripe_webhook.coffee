{ post } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  url = "/payments/stripe/webhook"
  post url, data, (err)->
    if err
      return res.send 500

    res.send 200
