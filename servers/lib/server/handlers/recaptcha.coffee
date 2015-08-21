{ recaptcha }    = KONFIG
simple_recaptcha = require 'simple-recaptcha'

module.exports = (req, res) ->

  { challenge, response } = req.body

  simple_recaptcha recaptcha, req.ip, challenge, response, (err) ->
    if err
      res.send err.message
      return

    res.send 'verified'
