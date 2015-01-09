utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


handleMachineRunning = (browser, targetUser, machineName) ->

  console.log targetUser + "'s " + machineName + ' VM is running, checking FileTree and Terminal...'

  browser
    .waitForElementVisible '.nfinder.file-container', 25000
    .waitForElementVisible '.terminal-pane .webterm', 25000


handleMachineNotRunning = (browser, targetUser, machineName) ->

  console.log


  targetUser + "'s " + machineName + ' VM is not running, starting the machine now!'

  helpers.waitForVMRunning browser, machineName



module.exports =

  paidUser: (browser) ->

    user =
      username : 'devrim'
      password : 'devrim'

    targetUser   = 'lolitacorkery'
    machineName  = 'bik-bik'

    helpers.beginTest(browser, user)

    browser.execute('KD.impersonate("' + targetUser + '")')


    machineLink     = '/IDE/' + machineName + '/my-workspace'
    machineSelector = "a[href='" + machineLink + "']"

    browser
      .waitForElementVisible   machineSelector, 30000
      .click                   machineSelector
      .element                 'css selector', machineSelector + '.running', (result) ->
        if result.status is 0
          handleMachineRunning browser, targetUser, machineName
        else
          handleMachineNotRunning browser, targetUser, machineName

    browser.end()
