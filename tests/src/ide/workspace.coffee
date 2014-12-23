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
    browser.end()


  createWorkspaceFromFileTree: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    folderData = helpers.createFolder(browser, user)
    name       = '~/' + folderData.name

    browser
      .waitForElementVisible  folderData.selector, 50000
      .click                  folderData.selector
      .waitForElementVisible  folderData.selector + ' + .chevron', 20000
      .click                  folderData.selector + ' + .chevron'
      .waitForElementVisible  '.context-list-wrapper', 20000
      .click                  '.context-list-wrapper li.workspace-from-here'
      .url (data) =>
        url    = data.value

        vmName = url.split('/IDE/')[1].split('/')[0]

        browser
          .waitForElementVisible  '.activity-sidebar .jtreeview-wrapper li' + ' a[href="/IDE/' + vmName + '/' + folderData.name + '"]', 20000 #Assertion
          .pause                  3000
          .assert.containsText    '.vm-info', name # Assertion
          .end()

