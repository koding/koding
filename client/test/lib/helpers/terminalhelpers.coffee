assert  = require 'assert'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'


module.exports =

  openNewTerminalMenu: (browser) ->

    browser
      .pause                   6000 # wait for sessions
      .waitForElementVisible   paneSelector + ' .visible-tab-handle.plus', 20000
      .click                   paneSelector + ' .visible-tab-handle.plus'
      .waitForElementVisible   '.context-list-wrapper li.new-terminal', 20000
      .moveToElement           '.context-list-wrapper li.new-terminal', 25, 20


  openTerminal: ( browser, openSessionTerminal = no, callback = -> ) ->

    sessionLink     = '.kdlistview-contextmenu ul:nth-of-type(1) .has-sub-items'
    openNewTerminal = '.kdlistview-contextmenu.default .open'

    browser.waitForElementVisible   'li.new-session', 20000

    if not openSessionTerminal
      browser
        .moveToElement           'li.new-session', 25, 20
        .click                   'li.new-session'
        .pause 6000, -> callback null # required
    else
      browser
        .moveToElement           sessionLink, 50, 50
        .waitForElementVisible   openNewTerminal, 20000
        .pause                   2000
        .click                   openNewTerminal
        .pause                   5000, -> callback null #wait for terminal to be displayed


  createTerminalSession: ( browser, user, callback = -> ) ->

    userName                   = user.username
    notActiveTerminalSelector  = paneSelector + ' .terminal:not(.active)'
    terminalTextAssertSelector = '.application-tabview .terminal.active .terminal-pane'

    @openNewTerminalMenu(browser)
    @openTerminal(browser)

    browser.element 'css selector', notActiveTerminalSelector, (result) =>
      if result.status isnt 0
        @openNewTerminalMenu(browser)
        @openTerminal(browser)

      browser
        .waitForElementVisible   notActiveTerminalSelector, 20000 # Assertion
        .waitForElementVisible   paneSelector + ' .terminal.active', 20000 # Assertion
        .pause 6000 # required for the Connecting...
        .assert.containsText     terminalTextAssertSelector, userName # Assertion
        .pause 10, -> callback()


  terminateAll: ( browser, callback = -> ) ->

    @openNewTerminalMenu(browser)

    browser
      .waitForElementVisible   'li.terminate-all', 20000
      .click                   'li.terminate-all'
      .pause                   10000 # required, wait to terminate all open sessions
      .element                 'css selector', '.autoremovepane-confirm', (result) ->
        if result.status is 0
          browser.click        '.autoremovepane-confirm button.red'

    @openNewTerminalMenu(browser)

    browser
      .assert.elementNotPresent   'li.terminate-all' # Assertion
      .pause 10, -> callback()
