braintree = require 'braintree'
$         = require 'jquery'
http      = require 'http'

gateway = braintree.connect  
  environment   : braintree.Environment.Sandbox
  merchantId    : '586xv7tjb3pstr7g'
  publicKey     : 'fmxs6jtqb33vyj9y'
  privateKey    : 'r7k3s27nwcvr5b7z'

newCustomerId = ->
  'kd' + Math.round Math.random() * 1000

getRandomAmount = ->
  Math.round(Math.random()*100000)/100

makeTransaction = (result)->
  console.log 'customer.create() result', result
  gateway.transaction.sale
    customerId  : result.customer.id
    amount      : getRandomAmount()
  , (err, result)->
    throw err if err
    console.log result

http.get
  host: 'www.fakenamegenerator.com'
  port: 80
  path: '/'
, (res)->
  html = ''
  res.on 'data', (data)->
    html += data
  res.on 'end', ->
    
    fake = $('.content .info', html)
    
    firstName = $('.given-name', fake).text()
    lastName  = $('.family-name', fake).text()
    email     = $('.email', fake).text().split(' ')[0].replace('teleworm','fake.koding')
    
    ###  
    gateway.transaction.sale
      amount            : '5.00'
      creditCard        :
        number          : '5105105105105100'
        expirationDate  : '05/10'
    , (err, result)->
      throw err if err
  
      if result.success
        console.log "Transaction id: #{result.transaction.id}"
      else
        console.log result.message
    ###
    customerId = newCustomerId()
    
    gateway.customer.find customerId, (err, result)->
      if err?.type is 'notFoundError' # handle notFoundError: create a new customer
        gateway.customer.create
          id                : customerId
          firstName         : firstName
          lastName          : lastName
          email             : email
          creditCard        :
            number          : '5105105105105100'
            expirationDate  : '05/10'
        , (err, result) ->
          throw err if err
          makeTransaction result
      else
        makeTransaction result