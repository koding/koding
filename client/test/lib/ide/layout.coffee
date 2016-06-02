helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'
layoutHelpers = require '../helpers/layouthelpers.js'

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

  layout: (browser) ->

    queue = [
      # splitPanesVertically
      (next) ->
        layoutHelpers.split browser, 'vertical', ->
          next null

      # splitPanesHorizontally
      (next) ->
        layoutHelpers.split browser, 'horizontal', ->
          next null

      # undoSplitPanes
      (next) ->
        layoutHelpers.undoSplit browser, yes, ->
          next null

      # undoSplitPanesNotShowOnScreen
      (next) ->
        newPaneSelector = '.kdsplitcomboview .kdsplitview-panel.panel-1 .application-tab-handle-holder'

        fn = ->
          browser.elements 'css selector', newPaneSelector, (result) ->
            if result.value.length is 1
              browser
                .waitForElementPresent '.panel-1 .general-handles .close-handle.hidden', 20000 # Assertion
                .pause 1, ->
                  next null, next
            else
              layoutHelpers.undoSplit(browser, no)
              fn()

        layoutHelpers.waitForSnapshotRestore(browser)
        fn()

      # openDrawingBoard
      (next) ->
        handleSelector     = '.kdtabhandle.drawing'
        activePaneSelector = '.kdtabpaneview.drawing.active .drawing-pane'

        fn = ->
          browser.elements 'css selector', handleSelector, (result) ->
            if result.value.length > 0
              console.log(' ✔ A drawing board is already opened. Ending test...')
              next null
            else
              layoutHelpers.openMenuAndClick(browser, '.new-drawing-board')

              browser
                .pause 4000
                .waitForElementVisible handleSelector + '.active', 20000
                .waitForElementVisible activePaneSelector, 20000 # Assertion
                .waitForElementVisible activePaneSelector + ' .drawing-board-toolbar', 20000 # Assertion
                .pause 1, -> next null

        layoutHelpers.waitForSnapshotRestore(browser)
        fn()

      # collapseExpandFileTree
      (next) ->
        tabSelector             = '.kdtabhandle-tabs.clearfix'
        fileTabSelector         = "#{tabSelector} .files"
        settingsTabSelector     = "#{tabSelector} .settings"
        collapseButton          = '.application-tab-handle-holder .general-handles'
        collapsedWindowSelector = '.kdview.kdscrollview.kdsplitview-panel.panel-0.floating'
        settingsHeaderSelector  = '.kdtabhandle-tabs .settings.kddraggable.active'

        browser
          .waitForElementVisible        fileTabSelector, 20000
          .pause                        3000 # wait for file tree to load
          .moveToElement                fileTabSelector, 5, 5
          .waitForElementVisible        collapseButton, 20000
          .click                        collapseButton
          .pause                        500
          .waitForElementVisible        collapsedWindowSelector, 20000
          .click                        fileTabSelector
          .pause                        500
          .waitForElementNotPresent     collapsedWindowSelector, 20000
          .click                        collapseButton
          .pause                        500
          .waitForElementVisible        collapsedWindowSelector, 20000
          .click                        settingsTabSelector
          .pause                        500
          .waitForElementNotPresent     collapsedWindowSelector, 20000
          .waitForElementVisible        settingsHeaderSelector, 20000
          .pause 1, -> next null


      # enterExitFullScreenFromIdeHeader
      (next) ->
        ideHeaderSelector           = '.panel-1 .pane-wrapper .application-tab-handle-holder'
        enterExitFullScreenSelector = "#{ideHeaderSelector} .general-handles .fullscreen-handle"
        collapsedSidebarSelector    = '.kdview.with-sidebar#kdmaincontainer.collapsed'

        layoutHelpers.waitForSnapshotRestore(browser)

        browser
          .waitForElementVisible     ideHeaderSelector, 20000
          .moveToElement             ideHeaderSelector, 10, 10
          .waitForElementVisible     enterExitFullScreenSelector, 20000
          .click                     enterExitFullScreenSelector
          .pause                     1500 #pause for screen animation to finish
          .moveToElement             ideHeaderSelector, 10, 10
          .pause                     1000
          .waitForElementVisible     enterExitFullScreenSelector, 20000
          .waitForElementVisible     collapsedSidebarSelector, 20000
          .click                     enterExitFullScreenSelector
          .pause                     500
          .waitForElementNotPresent  collapsedSidebarSelector, 20000
          .pause 1, -> next null
    ]

    async.series queue

  after: (browser) ->
    browser.end()
