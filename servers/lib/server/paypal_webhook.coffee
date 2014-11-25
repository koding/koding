{ post } = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  console.log "Got paypal webhook:", req.body

  post "/payments/paypal/webhook", req.body, (err, response)->
    console.log "Payments ERROR: ", err  if err
    res.status(200).send 'ok'
