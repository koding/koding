{ Model } = require 'bongo'

module.exports = class JRegistrationPreferences extends Model

  @setSchema
    isRegistrationEnabled : Boolean
