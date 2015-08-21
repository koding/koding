module.exports = (req, res) ->
  options = { subject: 'https://www.googleapis.com/auth/drive' }
  google_utils = require 'koding-googleapis'
  google_utils.authorize options, (err, authToken) ->
    return res.status(401).send err if err
    res.status(200).send authToken
