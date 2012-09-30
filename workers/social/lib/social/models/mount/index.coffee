jraphical = require 'jraphical'

module.exports = class JMount extends jraphical.Capsule
  {Model,secure} = require 'bongo'
  {Relationship} = require 'jraphical'
  
  @share()
  
  @set
    sharedMethods :
      instance    : ["save","update","remove"]
      static      : ["on"]

  save: secure (client,callback)->
    mount = @
    account = client.connection.delegate
    if account instanceof JGuest
      callback new Error "guest cant add mount"
    else
      Model::save.call @, (err)->
        if err
          callback err
        else
          account.addMount mount, callback

  update: secure (client,callback)->
    account = client.connection.delegate
    Relationship.one
      sourceId: account.getId()
      targetId: @getId()
      as: 'owner'
    , (err, ownership)=>
      if err
        callback err
      else
        unless ownership
          callback new Error "Access denied!"
        else
          Model::update.call @, callback
      