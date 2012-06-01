braintree = require 'braintree'
csv       = require 'csv'

gateway = braintree.connect
  environment   : braintree.Environment.Sandbox
  merchantId    : '586xv7tjb3pstr7g'
  publicKey     : 'fmxs6jtqb33vyj9y'
  privateKey    : 'r7k3s27nwcvr5b7z'

getNewCustomerId = ->
  'kd'.concat (''+Date.now())[-5..],
    '_'
    (''+Math.random()).split('.')[1][-5..]

getRandomAmount = ->
  (Math.round(Math.random()*100000)/100).toFixed 2

module.exports = (start, count, callback)->
  
  end = count + start
  transactionCount = 0
  lastResults = {
    successes : []
    failures  : []    
  }
  
  makeTransaction = (err, result)->
    customerResult = result?.customer
    if err
      err = new Error err.message
      registerFailure err, result
      console.log 'ran into an error...', err
    else unless customerResult
      err = new Error 'No customer result!'
      registerFailure err, result
      console.log result
    else
      amount      = getRandomAmount()
      customerId  = customerResult.id
      transaction = {
        amount
        customerId
      }
      console.log "trying to add a transaction...", transaction
      gateway.transaction.sale transaction, (err, result)->
        transactionResult = result?.transaction
        if err or not transactionResult
          err = new Error err.message
          registerFailure err, result
          console.log 'ran into an error...', err
        else
          console.log "finished a transaction. (id #{transactionResult.id})"
          registerSuccess customerResult, transactionResult

  finishOne = (success)->
    transactionCount++
    console.log 'finished #', transactionCount, if success then 'successfully' else 'in error'
    if transactionCount is count
      report = getSummaryReport()
      console.log 'all done!', report
      callback report

  registerSuccess = (customer, transaction)->
    lastResults?.successes?.push {
      customer
      transaction
    }
    finishOne yes

  registerFailure = (err, result)->
    lastResults?.failures?.push {
      err
      result
    }
    finishOne no
  
  getSummaryReport = (callback)->
    {
      count         : count
      start         : start
      end           : end
      successCount  : lastResults.successes.length
      failureCount  : lastResults.failures.length
      errors        : failure.err for failure in lastResults.failures
    }
  
  console.log "beginning a batch of #{count} starting with lineNumber #{start}..."
  
  names = csv().fromPath './fakenames.csv'

  names.on 'data', (line, lineNumber)->
    if start <= lineNumber < end
      [firstName, lastName, email] = line
      id = getNewCustomerId()
      fullName = "#{firstName} #{lastName}"
      console.log "trying to create a customer record for #{fullName}..."
      customer = {
        id
        firstName
        lastName
        email
        creditCard        :
          number          : '5105105105105100'
          expirationDate  : '05/10'
      }
      gateway.customer.create customer, makeTransaction

  names.on 'error', (err)-> registerFailure new Error 'had trouble reading the CSV'

  names.on 'end', (count)->
    console.log "done consuming #{count-1} names and emails from CSV!"