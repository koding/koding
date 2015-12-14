helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

module.exports =

  reinitVM: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openAdvancedSettings(browser)
    environmentHelpers.reinitVM(browser)

    browser.end()


  terminateVMForNonPayingUserAndCreateNewOne: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openAdvancedSettings(browser)
    environmentHelpers.terminateVM(browser)
    environmentHelpers.createNewVMForNonPayingUsers(browser)

    browser.end()


  terminateVm: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openAdvancedSettings(browser)
    environmentHelpers.terminateVM(browser)

    browser.end()