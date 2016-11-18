{ getContent } = require('terraform-yml')

module.exports = (req, res) ->
  { query } = req.params

  return res.end JSON.stringify getContent query
