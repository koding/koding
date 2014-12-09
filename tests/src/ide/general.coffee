utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  collapse: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    webPath     = '/home/' + user.username + '/Web'
    webSelector = "span[title='" + webPath + "']"
    file        = "span[title='" + webPath + '/' + 'index.html' + "']"

    helpers.openFolderContextMenu(browser, user, 'Web')

    browser
      .waitForElementVisible    '.expand', 20000
      .click                    '.expand'
      .pause                    2000 # required
      .waitForElementVisible    webSelector, 20000
      .click                    webSelector + ' + .chevron'
      .waitForElementVisible    '.collapse', 20000
      .click                    '.collapse'
      .waitForElementNotPresent file, 20000 # Assertion
      .end()


  makeTopFolder: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)

    webPath        = '/home/' + user.username + '/Web'
    filename       = helpers.createFile(browser, user)
    webSelector    = "span[title='" + webPath + "']"
    fileSelector   = "span[title='" + webPath + '/' +filename + "']"
    selectMenuItem = 'li.home'+user.username

    browser
      .waitForElementPresent   fileSelector, 20000 # Assertion
      .waitForElementVisible   webSelector, 10000
      .click                   webSelector
      .click                   webSelector + ' + .chevron'
      .waitForElementVisible   '.make-this-the-top-folder', 20000
      .click                   '.make-this-the-top-folder'
      .waitForElementVisible   '.vm-info', 20000
      .assert.containsText     '.vm-info', '~/Web'
      .waitForElementPresent   fileSelector, 20000 # Assertion

    helpers.openChangeTopFolderMenu(browser)

    browser
      .waitForElementVisible   selectMenuItem, 20000
      .click                   selectMenuItem
      .pause                   2000 # required
      .end()


  runCommandOnTerminal: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    time = Date.now()

    browser
      .waitForElementVisible  '.terminal-pane .console span.outlined', 20000
      .execute                "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('echo #{time}')"
      .execute                "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
      .pause                  5000
      .assert.containsText    '.terminal-pane .webterm', time
      .end()


  openEditorSettings: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible    '.kdtabhandle-tabs .settings', 20000
      .click                    '.kdtabhandle-tabs .settings'
      .waitForElementVisible    '.settings-pane .settings-header',20000 # Assertion
      .end()


  enterFullScreen: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible     '.application-tab-handle-holder', 20000
      .click                     '.application-tab-handle-holder .plus'
      .waitForElementVisible     '.context-list-wrapper', 20000
      .click                     '.context-list-wrapper li.enter-fullscreen'
      .waitForElementVisible     '.ws-tabview.fullscren', 20000 # Assertion
      .end()
