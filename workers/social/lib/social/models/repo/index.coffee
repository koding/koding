jraphical = require 'jraphical'

module.exports = class JRepo extends jraphical.Capsule
  
  {Model,secure} = require 'bongo'
  {Module,Relationship} = jraphical
  
  @share()
      
  save: secure (client,callback)->
    mount = @
    account = client.connection.delegate
    if account instanceof JGuest
      callback new Error "guest cant add repo"
    else
      Model::save.call mount, (err)->
        if err
          callback err
        else
          account.addRepo mount,callback

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

  remove: secure (client,callback)->
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
          Module::remove.call @, callback
  
  @repoSchemaTemplate =
    encapsulatedBy : JRepo
    sharedMethods :
      instance  : ["save","update","remove"]
      static    : ["on"]
    schema :
      title         : { type  : String }
      url           : { type  : String,  required  : yes }
      color         : { type  : String }
