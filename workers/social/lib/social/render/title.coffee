encoder = require 'htmlencode'

module.exports = (options = {}, callback) ->

  options.title or= 'Koding | Say goodbye to your localhost and write code in the cloud.'

  """<title>#{encoder.XSSEncode options.title}</title>"""
