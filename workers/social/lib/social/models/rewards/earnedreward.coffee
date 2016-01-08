{ Module } = require 'jraphical'

module.exports = class JEarnedReward extends Module

  { ObjectId } = require 'bongo'

  @set

    indexes           :
      originId        : 'sparse'

    # we need a compound index here
    # since bongo is not supporting them
    # we need to manually define following:
    #
    #   - originId, type, unit (unique)
    #

    sharedEvents      :

      static          : [ ]
      instance        : [ ]

    schema            :

      originId        :
        type          : ObjectId
        required      : yes

      type            :
        type          : String
        default       : -> 'disk'

      unit            :
        type          : String
        default       : -> 'MB'

      amount          :
        type          : Number
        default       : -> 0
