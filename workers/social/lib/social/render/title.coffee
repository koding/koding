encoder = require 'htmlencode'

module.exports = (options = {}, callback) ->

  options.title or= 'Modern Dev Environment Delivered · Koding'

  """<title>#{encoder.XSSEncode options.title}</title>"""
