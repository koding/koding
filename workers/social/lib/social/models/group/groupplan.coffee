{ Module } = require 'jraphical'

module.exports = class JGroupPlan extends Module

  @set
    indexes:
      name: 'unique'

    sharedEvents:
      static: []
      instance: []

    schema               :
      name               : String
      member             : Number
      validFor           : Number
      instancePerMember  : Number
      allowedInstances   : [String]
      maxInstance        : Number
      storagePerInstance : Number
      restrictions       :
        supports         : [String]
        provider         : [String]
        resource         : [String]
        custom           : Object

