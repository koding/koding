GeoIp = require 'geoip-lite'

countries = [
  'US', 'CA', 'AU', 'BE',
  'FR', 'DE', 'IT', 'NL',
  'SE', 'FI', 'GB'
]

module.exports = (req, res) ->

  clientIPAddress = req.headers['x-forwarded-for'] or req.connection.remoteAddress
  geo = GeoIp.lookup clientIPAddress

  unless KONFIG.environment is 'production'
    return res.status(200).send yes

  return res.status(200).send geo?.country in countries
