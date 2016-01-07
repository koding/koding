{ Model } = require 'bongo'

module.exports = class JLocationState extends Model

  @setSchema
    countryCode : String
    stateCode   : String
    state       : String
