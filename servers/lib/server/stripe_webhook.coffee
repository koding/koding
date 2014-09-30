{ post } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  url = "/payments/stripe/webhook"
  post url, data, (err)->
    if err
      return res.status(500).end()

    res.status(200).end()
