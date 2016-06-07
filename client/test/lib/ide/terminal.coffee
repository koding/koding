assert = require 'assert'
terminalHelpers = require '../helpers/terminalhelpers.js'
helpers = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'

paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'

module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res

      # go to IDE url
      (next) ->
        teamUrl = helpers.getUrl yes
        url = "#{teamUrl}/IDE"
        browser.url url, -> next null
    ]

    async.series queue, (err, result) ->
      done()  unless err


  terminal: (browser, done) ->

    user = utils.getUser()

    queue = [
      # terminateAll
      (next) ->
        terminalHelpers.createTerminalSession(browser, user)
        terminalHelpers.terminateAll browser, ->
          next null

      # createNewTerminalSession
      (next) ->
        terminalHelpers.createTerminalSession browser, user, ->
          next null

      # terminateSession
      (next) ->

        terminalHelpers.openNewTerminalMenu(browser)

        getSessionData = ->
          selector = '.kdcontextmenu ul + li.disabled'
          matcher  = /session-(\w+)\S+/

          return document.querySelector(selector).getAttribute('class').match(matcher)

        browser.execute getSessionData, [], (result) ->

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
              .getText sessionListSelector, (result) ->
                assert.equal(result.value.indexOf(sessionId), -1)
                browser.pause 1, -> next null

        # runCommandOnTerminal
        (next) ->
          terminalHelpers.createTerminalSession browser, user, ->
            helpers.runCommandOnTerminal browser, null, ->
              next null

        # renameTerminalTab
        (next) ->
          name            = helpers.getFakeText().split(' ')[0]
          tabSelector     = "#{paneSelector} .kdtabhandle.terminal"
          optionsSelector = "#{tabSelector} .options"
          renameSelector  = '.kdcontextmenu.terminal-context-menu .rename'
          editSelector    = "#{tabSelector}.edit-mode .hitenterview.tab-handle-input"
          tabNameSelector = "#{tabSelector} .tab-handle-text"


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
            .setValue                 editSelector, [name, browser.Keys.RETURN]
            .waitForElementNotPresent editSelector, 20000
            .assert.containsText      tabNameSelector, name #Assertion
            .pause 1, -> next null

    ]

    async.series queue

  after: (browser) -> browser.end()
