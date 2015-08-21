request = require 'request'

{ socialapi : { paymentwebhook : { port } } } = KONFIG

module.exports = (req, res) ->
  reqOptions =
    url    : "http://localhost:#{port}/-/payments/paypal/webhook"
    json   : true
    method : 'POST'

  reqOptions.body = req.body

  request reqOptions, (err, resp, body) ->
    return res.status(500).send err  if err
    res.status(200).end()
