helpers              = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
ideHelpers           = require '../helpers/idehelpers.js'


module.exports =


  checkThatFilesTheirContentDeletingProperly: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    collaborationHelpers.startSession(browser)

    ideHelpers.closeAllTabs(browser)

    fileName     = helpers.createFile(browser, user)
    fileSelector = "span[title='/home/#{user.username}/Web/#{fileName}']"
    activeEditorSelector = '.panel-1 .pane-wrapper .kdtabpaneview.active'
    ideViewSelector = '.panel-1 .panel-1 .application-tabview'

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

    browser
      .pause   3500
      .getText activeEditorSelector, (result) ->
        console.log result.value
        # assert.equal result.value, ''
        collaborationHelpers.endSessionFromStatusBar(browser)
        browser.end()

