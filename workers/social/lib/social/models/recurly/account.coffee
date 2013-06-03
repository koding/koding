{Module} = require 'jraphical'
payment  = require 'koding-payment'


module.exports = class JRecurlyAccount extends Module

  {secure}    = require 'bongo'
  crypto      = require 'crypto'
  createId    = require 'hat'

  @share()

  @set
    schema            :
      recurlyId       : String
    sharedMethods     :
      static          : [
        'create',
        'all', 'one', 'some'
      ]

  @create = secure (client, data, callback)->
    {delegate} = client.connection

    account = new JRecurlyAccount
      recurlyId : "account_#{createId()}"

    payment.setAccount account.recurlyId, data, (err, res)=>
      return callback err  if err
      unless err
        account.save =>
          return callback err  if err
          callback no, account