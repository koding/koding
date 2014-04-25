jraphical = require 'jraphical'

module.exports = class JCredentialData extends jraphical.Module

  @set

    indexes           :
      publicKey       : 'unique'

    sharedEvents      :

      static          : [ ]
      instance        : [ ]

    schema            :

      publicKey       :
        type          : String
        default       : require 'hat'

      meta            :
        type          : Object
        required      : yes
