{ argv } = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{ get } = require (
  '../../../workers/social/lib/social/models/socialapi/requests.coffee'
)

module.exports = (req, res) ->
  errMsg = (msg) ->
    {
      'description' : msg
      'error'       : 'bad_request'
    }

  { account_id, kloud_key } = req.query

  unless account_id
    return res.status(400).send errMsg 'account_id is required'

  unless kloud_key
    return res.status(401).send errMsg 'kloud_key is required'


  unless kloud_key is KONFIG.paymentwebhook.customersKey
    return res.status(401).send errMsg 'kloud_key is wrong'

  url  = "/payments/subscriptions/#{account_id}"
  url += '?default=false'

  get url, {}, (err, response) ->
    return res.status(400).send err  if err

    res.status(200).send response
