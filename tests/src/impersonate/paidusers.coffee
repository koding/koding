utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'
curl    = require 'curlrequest'


postToSlack = (message) ->

  options =
    url: 'https://hooks.slack.com/services/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'
    include: true
    method: 'POST'
    data:
      "payload": '{"channel": "#qa", "username": "qa-bot", "text": "' + message + '"}'

  curl.request options, (err, parts) -> console.log err  if err


handleMachineRunning = (browser, targetUser, machineName) ->

  browser
    .waitForElementVisible '.nfinder.file-container', 25000
    .waitForElementVisible '.terminal-pane .webterm', 25000

  postToSlack targetUser + "'s " + machineName + ' VM is running.'


handleMachineNotRunning = (browser, targetUser, machineName) ->

  postToSlack targetUser + "'s " + machineName + ' VM is not running, starting the machine now!'

  helpers.waitForVMRunning browser, machineName



module.exports =

  paidUser: (browser) ->

    user =
      username : 'fatihacet'
      password : 'xXbeDUPwtYhmw9KNKXiD8jf'

    targetUser      = 'devrim'
    machineName     = 'koding-vm-0'
    machineLink     = '/IDE/' + machineName + '/my-workspace'
    machineSelector = "a[href='" + machineLink + "']"


    helpers.beginTest(browser, user)

    browser
      .execute('KD.impersonate("' + targetUser + '")')
      .pause 15000
      .waitForElementVisible   machineSelector, 30000
      .click                   machineSelector
      .element                 'css selector', machineSelector + '.running', (result) ->
        if result.status is 0
          handleMachineRunning browser, targetUser, machineName
        else
          handleMachineNotRunning browser, targetUser, machineName

    browser.end()
