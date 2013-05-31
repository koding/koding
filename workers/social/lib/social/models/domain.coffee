{Model} = require 'bongo'
jraphical = require 'jraphical'

module.exports = class JDomain extends jraphical.Module
  {secure}  = require 'bongo'

  JAccount  = require './account'
  JVM       = require './vm'

  @share()

  @set
    softDelete      : no

    sharedMethods   :
      static        : ['one', 'some', 'all', 'count', 'createDomain', 'findByAccount']

    indexes         :
      domain        : 'unique'

    schema          :
      domain        :
        type        : String
        validate    : (value)-> !!value
        set         : (value)-> value.toLowerCase()
      owner         : JAccount
      vms           : [JVM]
      uid           : ->
        type        : Number
        set         : Math.floor
      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date
    '''
    relationships       :
      ownAccount        :
        targetType      : JAccount
        as              : 'owner'
      vms               :
        targetType      : JVM
        as              : 'vms'
    '''

  @createDomain: (options={}, callback)->
    model = new JDomain options
    model.save (err) ->
      callback? err, model

  @findByAccount: secure (client, selector, callback)->
    @all selector, (err, domains) ->
      if err then warn err
      domainList = ({name:domain.domain, id:domain._id, vms:domain.vms} for domain in domains)
      callback? err, domainList