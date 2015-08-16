request  = require 'request'

module.exports = (req, res) ->

  options =
    url   : 'https://api.lever.co/v0/postings/koding'
    json  : yes

  request options, (err, r, postings) ->
    res.status(404).send 'Not found' if err
    res.json postings
