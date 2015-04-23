helpers = require '../helpers/helpers.js'
assert  = require 'assert'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'


openNewTerminalMenu = (browser) ->

  browser
    .pause                   6000 # wait for sessions
    .waitForElementVisible   paneSelector + ' .visible-tab-handle.plus', 20000
    .click                   paneSelector + ' .visible-tab-handle.plus'
    .waitForElementVisible   '.context-list-wrapper li.new-terminal', 20000
    .moveToElement           '.context-list-wrapper li.new-terminal', 25, 20


openTerminal = (browser) ->

  openNewTerminalMenu(browser)

  browser
    .waitForElementVisible   'li.new-session', 20000
    .moveToElement           'li.new-session', 25, 20
    .click                   'li.new-session'
    .pause 6000 # required


createTerminalSession = (browser, user) ->

  userName                   = user.username
  notActiveTerminalSelector  = paneSelector + ' .terminal:not(.active)'
  terminalTextAssertSelector = '.application-tabview .terminal.active .terminal-pane'

  openTerminal(browser)

  browser.element 'css selector', notActiveTerminalSelector, (result) =>
    if result.status isnt 0
      openTerminal(browser)

    browser
      .waitForElementVisible   notActiveTerminalSelector, 20000 # Assertion
      .waitForElementVisible   paneSelector + ' .terminal.active', 20000 # Assertion
      .pause 6000 # required
      .assert.containsText     terminalTextAssertSelector, userName # Assertion


terminateAll = (browser) ->

  openNewTerminalMenu(browser)

  browser
    .waitForElementVisible   'li.terminate-all', 20000
    .click                   'li.terminate-all'
    .pause 30000 # required, wait to terminate all open sessions

  openNewTerminalMenu(browser)

  browser
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


  terminateSession: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    openNewTerminalMenu(browser)

    getSessionData = =>

      selector = '.kdcontextmenu ul + li.disabled'
      matcher  = /session-(\w+)\S+/

      return document.querySelector(selector).getAttribute('class').match(matcher)

    browser.execute getSessionData, [], (result) =>

      [cssClass, sessionId] = result.value
      sessionListSelector   = '.kdcontextmenu ul ul:nth-of-type(1).expanded'

      browser
        .waitForElementVisible  '.' + cssClass, 25000
        .moveToElement          '.' + cssClass, 10, 10
        .pause                  1000
        .click                  '.context-list-wrapper ul > ul.expanded ul.expanded .terminate'
        .pause                  5000

        openNewTerminalMenu(browser)

        browser
          .pause   1000
          .getText sessionListSelector, (result) =>
            assert.equal(result.value.indexOf(sessionId), -1)

            browser.end()


  # this test is deprecated with persistent storage
  # openOldTerminalSession: (browser) ->

  #   openSelector    = '.context-list-wrapper li.new-terminal + ul li + ul li.open:first-child'
  #   elementSelector = '.context-list-wrapper li.new-terminal + ul li.has-sub-items:not(.disabled)'
  #   user            = helpers.beginTest(browser)
  #   userName        = user.username

  #   helpers.waitForVMRunning(browser)

  #   createTerminalSession(browser, user)

  #   openNewTerminalMenu(browser)

  #   browser
  #     .waitForElementVisible   elementSelector, 20000
  #     .moveToElement           elementSelector, 25, 20
  #     .pause  2000 # required
  #     .waitForElementVisible   openSelector, 200000
  #     .moveToElement           openSelector, 25, 20
  #     .click                   openSelector
  #     .pause 6000 # required
  #     .waitForElementVisible   paneSelector + ' .terminal.active',20000 # Assertion
  #     .assert.containsText     '.application-tabview .terminal.active .terminal-pane', userName # Assertion
  #     .end()
