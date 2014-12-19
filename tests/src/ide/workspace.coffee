utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  createWorkspaceFromSidebar: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.createWorkspace(browser)
    browser.end()


  deleteWorkspace: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    workspaceName = helpers.createWorkspace(browser)

    helpers.deleteWorkspace(browser, workspaceName)
