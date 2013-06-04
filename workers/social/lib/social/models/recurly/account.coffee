{Module} = require 'jraphical'
payment  = require 'koding-payment'


module.exports = class JRecurlyAccount extends Module

  {secure}    = require 'bongo'
  crypto      = require 'crypto'
  createId    = require 'hat'

  @share()

  @set
    indexes           :
      recurlyId       : 'unique'
    schema            :
      recurlyId       : String
      creator         : String
      groupSlug       : String
    sharedMethods     :
      static          : [
        'create'
      ]
      instance        : [
        'update', 'attachToGroup'
      ]

  @create = secure (client, callback)->
    {delegate} = client.connection

    account = new JRecurlyAccount
      recurlyId : "account_#{createId()}"
      creatorId : delegate._id
      groupSlug : ""

    account.save (err)=>
      return callback err  if err
      callback no, account

  update: secure (client, data, callback)->
    payment.setAccount @recurlyId, data, (err, res)=>
      return callback err  if err
      unless err
        account.save =>
          return callback err  if err
          callback no, @

  attachToGroup: secure (client, data, callback)->
    {delegate} = client.connection
    if delegate._id is @creator

      @groupSlug = data.groupSlug
      @creator   = 0

      @save (err)=>
        return callback err  if err
        callback no, @
    else
      callback yes, null


  @getAccounts = secure (client, callback)->
    {delegate} = client.connection

    JRecurlyAccount.all
      creator   : delegate._id
      groupSlug : ""
    , callback

  @getGroupAccounts = secure (client, data, callback)->
    {delegate} = client.connection

    JRecurlyAccount.all
      creator   : delegate._id
      groupSlug : data.groupSlug
    , callback