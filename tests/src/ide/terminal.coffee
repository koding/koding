utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'
paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'


openNewTerminalMenu = (browser) ->

  browser
    .pause                   6000 # wait for sessions
    .waitForElementVisible   paneSelector + ' .visible-tab-handle.plus', 20000
    .click                   paneSelector + ' .visible-tab-handle.plus'
    .waitForElementVisible   '.context-list-wrapper li.new-terminal', 20000
    .moveToElement           '.context-list-wrapper li.new-terminal', 25, 20


createTerminalSession = (browser, user) ->

  userName = user.username

  openNewTerminalMenu(browser)

  browser
    .waitForElementVisible   'li.new-session', 20000
    .moveToElement           'li.new-session', 25, 20
    .click                   'li.new-session'
    .pause 6000 # required
    .waitForElementVisible   paneSelector + ' .terminal:not(.active)',20000 # Assertion
    .waitForElementVisible   paneSelector + ' .terminal.active',20000 # Assertion
    .pause 6000 # required
    .assert.containsText     '.application-tabview .terminal.active .terminal-pane', userName # Assertion


terminateAll = (browser) ->

  openNewTerminalMenu(browser)

  browser
    .waitForElementVisible   'li.terminate-all', 20000
    .click                   'li.terminate-all'
    .pause 3000 # required

  openNewTerminalMenu(browser)

  browser
    .pause 30000 # required
    .assert.elementNotPresent   'li.terminate-all' # Assertion


module.exports =


  terminateAll: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    createTerminalSession(browser, user)

    terminateAll(browser)
    browser.end()


  createNewTerminalSession: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    createTerminalSession(browser, user)
    browser.end()


  openOldTerminalSession: (browser) ->

    openSelector    = '.context-list-wrapper li.new-terminal + ul li + ul li.open:first-child'
    elementSelector = '.context-list-wrapper li.new-terminal + ul li.has-sub-items:not(.disabled)'
    user            = helpers.beginTest(browser)
    userName        = user.username

    helpers.waitForVMRunning(browser)

    createTerminalSession(browser, user)

    openNewTerminalMenu(browser)

    browser
      .waitForElementVisible   elementSelector, 20000
      .moveToElement           elementSelector, 25, 20
      .pause  2000 # required
      .waitForElementVisible   openSelector, 200000
      .moveToElement           openSelector, 25, 20
      .click                   openSelector
      .pause 6000 # required
      .waitForElementVisible   paneSelector + ' .terminal.active',20000 # Assertion
      .assert.containsText     '.application-tabview .terminal.active .terminal-pane', userName # Assertion
      .end()
