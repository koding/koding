encoder = require 'htmlencode'

module.exports = (options = {}, callback) ->

  options.title or= 'Koding'

  """<title>#{encoder.XSSEncode options.title}</title>"""
