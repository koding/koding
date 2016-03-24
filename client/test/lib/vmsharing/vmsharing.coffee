utils           = require '../utils/utils.js'
vmHelpers       = require '../helpers/vmhelpers.js'
terminalHelpers = require '../helpers/terminalhelpers.js'
helpers         = require '../helpers/helpers.js'
assert          = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    return if utils.suiteHookHasRun 'before'
    utils.registerSuiteHook 'before'


  shareVMAndAcceptInvitaion: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1
    vmSharingListSelector = '.vm-sharing.active'

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser

        callback = ->
          browser
            .waitForElementVisible  vmSharingListSelector, 20000
            .assert.containsText    "#{vmSharingListSelector} .listview-wrapper", participant.username
            .pause   7500 # wait for participant accept
            vmHelpers.removeAllInvitations(browser)
            browser.end()

        vmHelpers.handleInvite(browser, host, participant, callback)
      else
        vmHelpers.handleInvitation(browser, host, participant, yes)


  shareVMAndRejectInvitaion: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1
    vmSharingListSelector = '.vm-sharing.active'
    userAvatar            = "a.avatarview[href='/#{participant.username}']"

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser

        callback = ->
          browser
            .waitForElementNotPresent  userAvatar, 30000
            .end()

        vmHelpers.handleInvite(browser, host, participant, callback)
      else
        vmHelpers.handleInvitation(browser, host, participant, no)


  shareVMAcceptInvitaionAndRunOnTerminal: (browser) ->

    host                  = utils.getUser no, 0
    hostBrowser           = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant           = utils.getUser no, 1
    vmSharingListSelector = '.vm-sharing.active'
    terminalSelector      = '.kdview.ws-tabview .application-tabview .terminal'
    secondTabSelector     = '.ws-tabview .application-tab-handle-holder .kdtabhandle-tabs div.terminal:nth-of-type(2)'
    insertCommand         = "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input"
    executeCommand        = "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser

        callback = ->
          browser
            .waitForElementVisible  vmSharingListSelector, 20000
            .assert.containsText    "#{vmSharingListSelector} .listview-wrapper", participant.username
            .pause                  10000 # wait for participant accept and the terminal command to be pasted in
            .waitForTextToContain   terminalSelector, 'Text pasted into the terminal by participant'
            .pause                  3000 # wait for participant to clear terminal for second run
          vmHelpers.removeAllInvitations(browser)
          browser.end()

        vmHelpers.handleInvite(browser, host, participant, callback)
      else
        vmHelpers.handleInvitation(browser, host, participant, yes, no)

        browser.element 'css selector', secondTabSelector, (result) =>
          if result.status is -1
            terminalHelpers.openNewTerminalMenu(browser)
            terminalHelpers.openTerminal(browser, yes)

          helpers.runCommandOnTerminal(browser, 'Text pasted into the terminal')
          #clearing the terminal for second test run
          browser
            .execute  "#{insertCommand}('clear')"
            .execute  executeCommand
            .pause    5000
            .end()

