{ Module } = require 'jraphical'

module.exports = class JMachine extends Module

  { ObjectId } = require 'bongo'

  @set

    indexes             :
      kiteId            : 'unique'

    sharedEvents        :
      static            : [ ]
      instance          : [ ]

    schema              :

      kiteId            :
        type            : String

      vendor            :
        type            : String
        required        : yes

      label             :
        type            : String
        default         : ""

      users             : Array
      groups            : Array

      state             :
        type            : String
        enum            : ["Wrong type specified!",
          ["active", "not-initialized", "removed", "suspended"]
        ]
        default         : "not-initialized"

      meta              : Object
