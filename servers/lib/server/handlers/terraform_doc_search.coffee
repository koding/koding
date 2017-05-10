{ search } = require('terraform-yml')

module.exports = (req, res) ->

  { query } = req.body

  return res.end JSON.stringify search query ? ' '
