helpers         = require '../helpers/helpers.js'
assert          = require 'assert'
terminalHelpers = require '../helpers/terminalhelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'


module.exports =

  terminateAll: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    terminalHelpers.createTerminalSession(browser, user)

    terminalHelpers.terminateAll(browser)
    browser.end()


  createNewTerminalSession: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    terminalHelpers.createTerminalSession(browser, user)
    browser.end()


  terminateSession: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    terminalHelpers.openNewTerminalMenu(browser)

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

        terminalHelpers.openNewTerminalMenu(browser)

        browser
          .pause   1000
          .getText sessionListSelector, (result) =>
            assert.equal(result.value.indexOf(sessionId), -1)

            browser.end()


  runCommandOnTerminal: (browser) ->

    user = helpers.beginTest(browser)

    helpers.waitForVMRunning(browser)
    terminalHelpers.createTerminalSession(browser, user)

    helpers.runCommandOnTerminal(browser)
    browser.end()


  renameTerminalTab: (browser) ->

    name            = helpers.getFakeText().split(' ')[0]
    tabSelector     = "#{paneSelector} .kdtabhandle.terminal"
    optionsSelector = "#{tabSelector} .options"
    renameSelector  = ".kdcontextmenu.terminal-context-menu .rename"
    editSelector    = "#{tabSelector}.edit-mode .hitenterview.tab-handle-input"
    tabNameSelector = "#{tabSelector} .tab-handle-text"

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    terminalHelpers.createTerminalSession(browser, user)

    browser
      .waitForElementVisible    tabSelector, 20000
      .moveToElement            tabSelector, 64, 18
      .waitForElementVisible    optionsSelector, 20000
      .click                    optionsSelector
      .waitForElementVisible    renameSelector, 20000
      .click                    renameSelector
      .waitForElementPresent    editSelector, 20000
      .clearValue               editSelector
      .setValue                 editSelector, [name,browser.Keys.RETURN]
      .waitForElementNotPresent editSelector, 20000
      .assert.containsText      tabNameSelector, name #Assertion
      .end()


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
