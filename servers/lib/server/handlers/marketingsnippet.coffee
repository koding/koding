request = require 'request'

module.exports = (req, res) ->

  { name } = req.params

  url      = "http://alex-ionochkin.github.io/content-rotator/snippets/#{name}"
  options  = { url }

  request options, (err, response, body) ->

    console.log response.statusCode
    return res.status(400).send err  if response.statusCode >= 400

    return res.status(200).send body
