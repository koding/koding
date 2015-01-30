request = require 'request'

{ socialapi : {paymentwebhook : { port } } } = KONFIG

module.exports = (req, res) ->
  reqOptions =
    url    : "http://localhost:#{port}/-/payments/paypal/webhook"
    json   : true
    method : 'POST'

  reqOptions.body = req.body

  request reqOptions, -> res.status(200).send 'ok'
