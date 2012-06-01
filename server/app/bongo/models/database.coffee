class JDatabaseUser extends jraphical.Module
  @set
    schema :
      username : {type: String, required:yes}
      password : {type: String, required:yes}

class JDatabase extends jraphical.Capsule
  @reIndex()
  @set
    indexes:
      uniqueName : "unique"

  {Model,secure} = bongo
  {Module,Relationship} = jraphical
  
  @share()

  save: secure (client,callback)->

    finishSaving = (aDatabaseInstance,account,callback)->
      Model::save.call aDatabaseInstance, (err)->
        if err
          callback err
        else
          account.addDatabase aDatabaseInstance,callback

    database = @
    account = client.connection.delegate
    if account instanceof JGuest
      callback new Error "guest cant add database"
    else
      switch @data.bongo_.constructorName
        when "JDatabaseMySql"
          account.tellKiteInternal account:account, kiteName:"databases",toDo:"createMysqlDatabase",withArgs: 
            dbUser  : @data.users[0].username
            dbPass  : @data.users[0].password
            dbName  : @data.name
          ,(err,res)=> 
            unless err
              @data.users[0].username = res.dbUser
              @data.users[0].password = res.dbPass
              @data.name              = res.dbName
              @data.host              = res.host
              finishSaving @,account,callback
            else callback err
        when "JDatabaseMongo"
          account.tellKiteInternal account:account, kiteName:"databases",toDo:"createMongoDatabase",withArgs:
            dbUser  : @data.users[0].username
            dbPass  : @data.users[0].password
            dbName  : @data.name
          ,(err,res)=>
            unless err
              # @data.users[0].username = res.dbUser
              # @data.users[0].password = res.dbPass
              # @data.name              = res.dbName
              # @data.host              = res.host
              finishSaving @,account,callback
            else callback err
        else
          callback "not implemented yet"
        


  update: secure (client,callback)->
    
    finishUpdating = (aDatabaseInstance, callback)->
      Model::update.call aDatabaseInstance,(err)->        
        console.log err if err
        aDatabaseInstance.emit "update"
        callback err
    account = client.connection.delegate
    Relationship.one
      sourceId: account.getId()
      targetId: @getId()
      as: 'owner'
    , (err, ownership)=>
      if err
        console.log "stuck on ownership"
        callback err
      else
        unless ownership
          callback new Error "Access denied!"
        else
          # console.log @data
          switch @data.bongo_.constructorName
            when "JDatabaseMySql"
              account.tellKiteInternal account:account, kiteName:"databases",toDo:"changeMysqlPassword",withArgs: 
                dbUser  : @data.users[0].username
                dbPass  : @data.users[0].password
                dbName  : @data.name
              ,(err,res)=> 
                unless err then finishUpdating @,callback
                else callback err
            when "JDatabaseMongo"
              account.tellKiteInternal account:account, kiteName:"databases",toDo:"changeMongoPassword",withArgs:
                dbUser      : @data.users[0].username
                dbName      : @data.name
                newPassword : @data.users[0].password
              ,(err,res)=>
                unless err               
                  # @data.users[0].username = res.dbUser
                  # @data.users[0].password = res.newPassword
                  # @data.name              = res.dbName
                  # @data.host              = res.host
                  finishUpdating @,callback
                else callback err
            else
              callback "not implemented yet!"
          

  remove: secure (client,callback)->
    account = client.connection.delegate
    
    finishRemove = (anInstance,callback)->
      Module::remove.call anInstance, callback
    
    Relationship.one
      sourceId: account.getId()
      targetId: @getId()
      as: 'owner'
    , (err, ownership)=>
      if err
        console.log "stuck on ownership"
        callback err
      else
        unless ownership
          callback new Error "Access denied!"
        else
          switch @data.bongo_.constructorName
            when "JDatabaseMySql"
              account.tellKiteInternal account:account, kiteName:"databases",toDo:"removeMysqlDatabase",withArgs: 
                dbUser  : @data.users[0].username
                dbName  : @data.name
              ,(err,res)=>                 
                finishRemove @,callback
                console.log "there was a problem deleting dbName: #{@data.name}, but it's removed anyway from mongo.",err if err
            when "JDatabaseMongo"
              console.log @data
              account.tellKiteInternal account:account, kiteName:"databases",toDo:"removeMongoDatabase",withArgs: 
                dbUser  : @data.users[0].username
                dbName  : @data.name
              ,(err,res)=>                 
                finishRemove @,callback
                console.log "there was a problem deleting dbName: #{@data.name}, but it's removed anyway from mongo.",err if err
            else
              callback "not implemented yet"

  
  @databaseSchemaTemplate =
    encapsulatedBy  : JDatabase
    sharedMethods   :
      instance      : ["save","update","remove"]
      static        : ["on"]
    schema          :
      title         : { type  : String }
      host          : { type  : String,  required  : yes }
      name          : { type  : String,  required  : yes }
      color         : { type  : String }
      users         : { type  : [JDatabaseUser]}
      uniqueName    : { type  : String, get : -> @constructor.name+@name}

class JDatabaseMySql extends JDatabase
  
  @share()
  @set @databaseSchemaTemplate

class JDatabaseMongo extends JDatabase
  
  @share()
  @set @databaseSchemaTemplate
  
class JDatabasePostGre extends JDatabase
  
  @share()
  @set @databaseSchemaTemplate

class JDatabaseCouch extends JDatabase
  
  @share()
  @set @databaseSchemaTemplate
