jraphical   = require 'jraphical'
CActivity   = require './activity'
JAccount    = require './account'
KodingError = require '../error'

class JUserKite extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      instance        : ['revoke']
      static          : ['create', 'fetchAll', 'fetchByKey']
    schema            :
      latest_s3url    : String
      kitename        : String
      owner           : String
      latest_version  : 
        type: String # ???
        default:1
      createdAt   :
        type      : Date
        default   : -> new Date

  newVersion: (cb)=>
    kiteversion = new JUserKiteVersion
      s3url: @latest_s3url
      kitename: @kitename
      owner: @owner
      version: @latest_version
    kiteversion.save (err)->
      console.log "error", err
      cb(err)

  @fetchOrCreate: (data, callback)=>
    JUserKite.one
      kitename: data.kitename
      owner: data.account_id #or data.account?._id
    , (err, userkite)->
      console.log "the error: ", err
      if err
        callback err
      else if not userkite
        userkite = new JUserKite
          kitename      : data.kitename
          latest_s3url  : data.latest_s3url
          owner         : data.account_id #or data.account?._id
        userkite.save (err)->
          if err
            callback err
          else
            callback null, userkite
      else
        JUserKite.update {_id: userkite.data._id}, 
                            {$set: 
                                latest_version: parseInt(userkite.data.latest_version) + 1,
                                latest_s3url: data.latest_s3url
                            }
                          , (err)->
          if err 
            return callback(err)
          callback(null, userkite)


class JUserKiteVersion extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      instance        : ['revoke']
      static          : ['create', 'fetchAll', 'fetchByKey']
    schema            :
      s3url           : String
      kitename        : String
      owner           : String
      version         : String
      createdAt   :
        type      : Date
        default   : -> new Date


  @create = (account, data, callback)->
    key = new JKodingKey
      kitename : data.kitename
      s3url    : data.s3url
      owner    : account._id

    key.save (err)->
      if err
        callback err
      else
        callback null, key


class JUserKiteInstance extends jraphical.Module
  
  # dont know if we really need this ??

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      instance        : ['revoke']
      static          : ['create', 'fetchAll', 'fetchByKey']
    schema            :
      ipaddr          : String
      lxcid           : String
      owner           : String
      kite            : String
      kite_version_id : String
      run_started     : Date
      createdAt   :
        type      : Date
        default   : -> new Date



module.exports = {JUserKite, JUserKiteInstance, JUserKiteVersion}