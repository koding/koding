jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh = yes

module.exports = class JRecurlyCharge extends jraphical.Module

  {secure} = require 'bongo'
  
  JRecurlyToken = require './token'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'all', 'one', 'some',
        'getToken', 'charge'
      ]
      instance     : [
        'cancel'
      ]
    schema         :
      uuid         : String
      userCode     : String
      amount       : Number
      status       : String
      lastUpdate   : Number

  @getToken = secure (client, data, callback)->
    {delegate} = client.connection
    JRecurlyToken.createToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
    , callback

  @charge = secure (client, data, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    JRecurlyToken.checkToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
      pin: data.pin
    , (status)=>
      unless status
        callback yes, {}
      else
        payment.addUserTransaction userCode,
          amount         : data.amount
        , (err, charge)=>
          return callback err  if err
          pay = new JRecurlyCharge
            uuid       : charge.uuid
            amount     : charge.amount
            userCode   : userCode
            status     : charge.status
          pay.save ->
            console.log arguments
            callback no, pay

  cancel: secure (client, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    payment.deleteUserTransaction userCode,
      uuid   : @uuid
      amount : @amount
    , (err, sub)=>
      return callback yes  if err
      @status   = 'refunded'
      @save =>
        callback no, @