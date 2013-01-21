jraphical = require 'jraphical'

module.exports = class JLimit extends jraphical.Module

  @share()

  @set
    schema      :
      quota     :
        type    : Number
        default : 0
      usage     :
        type    : Number
        default : 0

  getValue:-> @getAt('quota') - @getAt('usage')