request = require 'request'
crypto  = require 'crypto'

module.exports = (req, res) ->

  { email } = req.body

  return res.status(400).send 'Email is not set'  unless email

  _hash     = (crypto.createHash('md5').update(email.toLowerCase().trim()).digest('hex')).toString()
  _url      = "https://www.gravatar.com/#{_hash}.json"
  _request  =
    url     : _url
    headers : { 'User-Agent': 'request' }
    timeout : 3000

  request _request, (err, response, body) ->

    return res.status(400).send err.code  if err

    if body isnt 'User not found'
      try
        gravatar = JSON.parse body
      catch
        return res.status(400).send 'User not found'

      return res.status(200).send gravatar

    res.status(400).send body
