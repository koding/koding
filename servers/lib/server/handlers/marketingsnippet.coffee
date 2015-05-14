request = require 'request'

###*
 * Method performs a request for marketing snippet resources
 * which are located on content-rotator github repo and returns their content
 * in the response
###
module.exports = (req, res) ->

  { path } = req.params

  url      = "http://alex-ionochkin.github.io/content-rotator/snippets/#{req.params[0]}"
  options  = { url }

  request options, (err, response, body) ->

    return res.status(400).send err  if err or response.statusCode >= 400

    return res.status(200).send body
