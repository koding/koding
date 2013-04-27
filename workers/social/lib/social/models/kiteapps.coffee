jraphical = require 'jraphical'

module.exports = class JKiteCall extends jraphical.Module

  {Relationship} = jraphical

  {secure} = require 'bongo'

  @share()

  @set
    softDelete : yes
    permissions: [
      'read kiteapps'
      'create kiteapps'
      'edit kiteapps'
      'delete kiteapps'
      'delete own kiteapps'
    ]  
    sharedMethods   :
      instance      : [
          'delete'
        ]
      static        : [
          'create', 'get', 'inc'
        ]
    schema          :
      username      :
        type        : String
        required    : yes
      methodName    :
        type        : String
        required    : yes
      kiteName      :
        type        : String
        required    : yes        
      count         :
        type        : Number
        required    : no
    
  @create = (data, callback)->
    data.count = 1
    kiteApp = new JKiteCall data
    kiteApp.save (err)->
      if err
        callback err
      else
        callback null, kiteApp

  @get = secure (data, callback)->

    @one {
     username : data.username
     kiteName : data.kiteName
     methodName : data.methodName
    }, (err, appData)=>
      if err
        callback err
      else
        callback null, appData

  @inc = (data, callback)->

    @get data , (err, appData)=>
      if err
        callback err
      else
        if appData instanceof JKiteCall

          appData.update {$inc: 'count': 1} , (err) =>
            callback null, appData
        else 
          @create data, callback

  delete: secure ({connection:{delegate}}, callback)->
    @remove callback
