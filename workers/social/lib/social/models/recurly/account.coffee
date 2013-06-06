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

  # @createGroupAccount = secure (client, group, callback)->
  #   account = new JRecurlyAccount
  #     recurlyId : "group_#{group.slug}"
  #     groupSlug : group.slug

  #     # data.username  = "group_#{group.slug}" 
  #     # data.email     = 'group@example.com'
  #     # data.firstName = 'Group'
  #     # data.lastName  = group.title

  #     payment.setAccount account.recurlyId, data, (err, res)=>
  #       return callback err  if err
  #       unless err
  #         @save (err)=>
  #           return callback err  if err
  #           callback no, @

  @create = secure (client, callback)->
    {delegate} = client.connection

    account = new JRecurlyAccount
      recurlyId : "account_#{createId()}"
      creator   : delegate._id.toString()
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

  attachToGroup: secure (client, group, callback)->
    {delegate} = client.connection
    if delegate._id.toString() is @creator

      @groupSlug = group.slug

      data =
        username  : "group_#{group.slug}" 
        email     : 'group@example.com'
        firstName : 'Group'
        lastName  : group.title

      payment.setAccount2 @recurlyId, data, (err, res)=>
        return callback err  if err
        unless err
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