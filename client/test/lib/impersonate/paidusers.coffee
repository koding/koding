helpers = require '../helpers/helpers.js'
assert  = require 'assert'
curl    = require 'curlrequest'


postToSlack = (message) ->

  options =
    url: 'https://hooks.slack.com/services/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'
    include: true
    method: 'POST'
    data:
      "payload": '{"channel": "#qa", "username": "crow", "icon_url": "https://koding-cdn.s3.amazonaws.com/images/qa-crow-logo.png", "text": "' + message + '"}'

  curl.request options, (err, parts) -> console.log err  if err


handleMachineRunning = (browser, targetUser, machineName) ->

  browser
    .waitForElementVisible '.nfinder.file-container', 25000
    .waitForElementVisible '.terminal-pane .webterm', 25000

  postToSlack targetUser + "'s " + machineName + ' VM is running.'


handleMachineNotRunning = (browser, targetUser, machineName) ->

  postToSlack targetUser + "'s " + machineName + ' VM is not running, starting the machine now!'

  helpers.waitForVMRunning browser, machineName


getUserData = (callback) ->

  options =
    url   : 'https://koding.com/-/payments/customers?key=R1PVxSPvjvDSWdlPRVqRv8IdwXZB'

  curl.request options, (err, result) ->
    if err
      return console.log "Couldn't get user data"

    data   = JSON.parse result
    random = Math.floor(Math.random() * (data.length - 0) + 0)

    callback data[random].username, data[random].vms


module.exports =

  paidUser: (browser) ->

    getUserData (username, vms) ->

      user =
        username : 'fatihacet'
        password : 'xXbeDUPwtYhmw9KNKXiD8jf'

      machineName     = vms[0]
      machineLink     = "/IDE/#{machineName}"
      machineSelector = ".sidebar-machine-box.#{machineLink}"

      unless machineName
        postToSlack username + " doesn't have a always on VM, ignoring user..."
        browser.waitForElementVisible '.hello', 100

      console.log 'Impersonating user', username, 'for machine', machineName

      helpers.beginTest(browser, user)

      browser
        .execute('KD.impersonate("' + username + '")')
        .pause 15000
        .waitForElementVisible   machineSelector, 30000
        .click                   machineSelector
        .element                 'css selector', machineSelector + ' .running', (result) ->
          if result.status is 0
            handleMachineRunning browser, username, machineName
          else
            handleMachineNotRunning browser, username, machineName

      browser.end()


  afterEach: (browser) ->

    module.exports.paidUser(browser)
