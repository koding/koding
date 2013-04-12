{Model} = require 'bongo'

module.exports = class JVM extends Model

  @setSchema
    ip              : String
    ldapPassword    : String
    name            : String
    users           : [String]
    groups          : [String]