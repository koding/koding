encoder = require 'htmlencode'

module.exports = (options = {}, callback) ->

  options.title or= 'Koding | A New Way For Developers To Work'

  """<title>#{encoder.XSSEncode options.title}</title>"""
