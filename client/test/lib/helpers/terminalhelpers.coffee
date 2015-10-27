helpers = require '../helpers/helpers.js'
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


  openTerminal: (browser) ->

    browser
      .waitForElementVisible   'li.new-session', 20000
      .moveToElement           'li.new-session', 25, 20
      .click                   'li.new-session'
      .pause 6000 # required
