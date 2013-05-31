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
      ]
    schema         :
      uuid         : String
      accounting   : String
      userCode     : String
      amount       : Number
      desc         : String
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
        payment.addUserCharge userCode,
          amount         : data.amount
          accountingCode : data.code
          desc           : data.desc
        , (err, charge)=>
          return callback err  if err
          if data.amount > 10 * 100
            payment.chargeUserPending userCode, (err, invoice)=>
              return callback err  if err
              pay = new JRecurlyCharge
                uuid       : charge.uuid
                amount     : charge.amount
                desc       : data.desc
                userCode   : userCode
                accounting : data.code
              pay.save =>
                callback no, pay