{Module} = require 'jraphical'

module.exports = class JSessionHistory extends Module
  @set
    indexes         :
      username      : 1
      createdAt     : 1
    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      username      :
        type        : String
        required    : yes
      createdAt     :
        type        : Date
        default     : -> new Date
      data          : Object

  @create = (data, callback)->
    inst = new JSessionHistory data
    inst.save callback
