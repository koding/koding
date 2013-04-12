{Model} = require 'bongo'

module.exports = class JVM extends Model

  @share()

  @set
    permissions       :
      'sudoer'        : []
    schema            :
      ip              : String
      ldapPassword    : String
      name            : String
      users           : [String]
      groups          : [String]