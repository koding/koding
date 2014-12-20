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


  createWorkspaceFromFileTree: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    helpers.openFolderContextMenu(browser, user, 'Web')

    browser
      .waitForElementVisible   '.kdlistview-contextmenu', 25000
      .waitForElementVisible   '.kdlistview-contextmenu li.workspace-from-here', 25000
      .click                   '.kdlistview-contextmenu li.workspace-from-here'
      .url (data) =>
        url    = data.value

        vmName = url.split('/IDE/')[1].split('/')[0]

        browser
          .waitForElementPresent   'a[href="/IDE/' + vmName + '/web"]', 40000 # Assertion
          .assert.urlContains      '/web' # Assertion
          .waitForElementVisible   '.vm-info', 20000
          .assert.containsText     '.vm-info', '~/Web' # Assertion

        helpers.deleteWorkspace(browser, 'web')

    browser.end()
