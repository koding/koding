koding  = require './../bongo'
request = require 'request'
KONFIG  = require 'koding-config-manager'

API_URI = 'https://koding.wufoo.com/api/v3/forms.json'
API_KEY = '5SDG-SAZO-UNLK-3F9K'
USERNAME = 'koding'
PASSWORD = 'balbalsdkasd'

module.exports = (req, res, next) ->

  request
    uri: API_URI
    method: 'GET'
    auth:
      'username'        : 'AOI6-LFKL-VM1Q-IEX9'
      'password'        : 'footastic'
      'sendImmediately' : false
  , (err, response, body) ->

    return res.status(500).send 'an error occured'  if err or not body
    return res.status(200).send body
