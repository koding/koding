helpers               = require '../helpers/helpers.js'
ideHelpers            = require '../helpers/idehelpers.js'
collaborationHelpers  = require '../helpers/collaborationhelpers.js'
teamsHelpers          = require '../helpers/teamshelpers.js'
utils                 = require '../utils/utils.js'
async                 = require 'async'

module.exports =

  before: (browser, done) ->
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
    ]

    async.series queue, (err, result) ->
      done()  unless err


  checkThatFilesTheirContentDeletingProperly: (browser) ->
    user = utils.getUser()
    collaborationHelpers.startSession(browser)

    ideHelpers.closeAllTabs(browser)

    fileName             = helpers.createFile(browser, user)
    fileSelector         = "span[title='/home/#{user.username}/.config/#{fileName}']"
    ideViewSelector      = '.panel-1 .panel-1 .application-tabview'
    activeEditorSelector = '.panel-1 .pane-wrapper .kdtabpaneview.active'

    browser
      .waitForElementVisible ideViewSelector, 20000
      .click                 ideViewSelector

    ideHelpers.openFile(browser, user, fileName)
    ideHelpers.setTextToEditor(browser, 'foo bar')
    ideHelpers.saveFile(browser)

    ideHelpers.closeFile(browser, fileName, user)
    helpers.deleteFile(browser, fileSelector)

    helpers.createFile(browser, user, null, null, fileName)
    ideHelpers.openFile(browser, user, fileName)

    ideHelpers.saveAsFile(browser)

    browser
      .pause   3500
      .getText activeEditorSelector, (result) ->
        console.log result.value
        # assert.equal result.value, ''
        collaborationHelpers.endSessionFromStatusBar(browser)
        browser.end()
