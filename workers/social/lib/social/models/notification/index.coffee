jraphical = require 'jraphical'

module.exports = class JNotification extends jraphical.Module

  {Base, Model, ObjectRef, ObjectId, dash, daisy} = require 'bongo'

  @trait __dirname, '../../traits/notifying'

  @set
    broadcastable   : yes
    schema          :
      actor         : [ObjectRef]
      action        : String
      subject       : ObjectRef

  constructor:->
