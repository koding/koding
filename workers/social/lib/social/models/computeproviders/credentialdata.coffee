{ Module } = require 'jraphical'

module.exports = class JCredentialData extends Module

  { ObjectId } = require 'bongo'

  @set

    indexes           :
      publicKey       : 'unique'

    schema            :

      publicKey       :
        type          : String
        default       : require 'hat'

      meta            :
        type          : Object
        required      : yes

      originId        :
        type          : ObjectId
        required      : yes
