{ Module } = require 'jraphical'

module.exports = class JClaimedReferral extends Module

  { ObjectId } = require 'bongo'

  @set

    indexes           :
      originId        : 'sparse'

    sharedEvents      :

      static          : [ ]
      instance        : [ ]

    schema            :

      originId        :
        type          : ObjectId
        required      : yes

      type            :
        type          : String
        default       : -> "disk"

      unit            :
        type          : String
        default       : -> "MB"

      amount          :
        type          : Number
        default       : -> 0
