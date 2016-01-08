{ Module } = require 'jraphical'

module.exports = class JCredentialData extends Module

  { ObjectId } = require 'bongo'

  @set

    indexes           :
      identifier      : 'unique'

    sharedEvents      :

      static          : [ ]
      instance        : [ ]

    schema            :

      identifier      :
        type          : String
        default       : require 'hat'

      meta            :
        type          : Object
        required      : yes

      originId        :
        type          : ObjectId
        required      : yes
