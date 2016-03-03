utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
environmentHelpers   = require '../helpers/environmenthelpers.js'
vmHelpers            = require '../helpers/vmhelpers.js'
assert               = require 'assert'


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

