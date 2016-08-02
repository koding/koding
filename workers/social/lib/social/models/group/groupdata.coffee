{ Module } = require 'jraphical'

module.exports = class JGroupData extends Module

  @set
    indexes       :
      slug        : 'unique'

    sharedEvents  :
      static      : []
      instance    : []

    schema        :
      slug        :
        type      : String
        validate  : require('../name').validateName
        set       : (value) -> value.toLowerCase()

      data        : Object
