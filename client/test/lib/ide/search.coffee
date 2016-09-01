helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'
paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'
activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'

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

  search: (browser) ->

    user = utils.getUser()

    queue = [

      # findInFiles
      (next) ->
        contentSearchModalSelector  = '.content-search-modal'
        findInFilesSelector         = '.kdlistview-contextmenu li.search-in-all-files'
        matchedWordSelector         = '.content-search-result pre p.match'
        activeUntitledFileSelector  = "#{paneSelector} .untitledtxt.active"
        fileNameSelector            = '.content-search-result .filename > span'

        ideHelpers.openNewFile browser, ->
          ideHelpers.openContextMenu browser, ->
            browser
              .waitForElementVisible     findInFilesSelector, 20000
              .click                     findInFilesSelector
              .waitForElementVisible     contentSearchModalSelector, 20000
              .setValue                  contentSearchModalSelector + ' input[name=findInput]', '# for examples'
              .click                     contentSearchModalSelector + ' button.search'
              .waitForElementVisible     paneSelector + ' .search-result', 20000 # Assertion
              .waitForElementNotPresent  activeUntitledFileSelector, 20000 # Assertion
              .pause                     5000
              .getText                   fileNameSelector, (result = {}) ->

                fileName  = result.value.split('/')?.reverse()[0]
                lowercase = fileName?.replace(/\./g, '').toLowerCase()

                return next null unless lowercase

                editorSelector    = ".panel-1 .kdtabpaneview.active.#{lowercase} .ace_content"

                browser
                  .waitForElementVisible     matchedWordSelector, 20000
                  .click                     matchedWordSelector
                  .waitForElementNotPresent  paneSelector + '.search-result .active', 20000 # Assertion
                  .waitForElementVisible     editorSelector, 20000
                  .pause                     3000 # wait for content
                  .assert.containsText       editorSelector, '# for examples'
                  .pause 1, -> next null

      # jumpToFile
      (next) ->

        searchModalSelector  = '.file-finder'
        findInFilesSelector  = '.kdlistview-contextmenu li.find-file-by-name'
        filename = 'test.txt'
        filenameClassname = 'testtxt'
        helpers.createFileFromMachineHeader browser, user, filename, yes, (res) ->

          ideHelpers.openNewFile(browser)
          ideHelpers.openContextMenu(browser)

          paneSelector         = ".pane-wrapper .kdsplitview-panel .application-tab-handle-holder .#{filenameClassname}"

          browser
            .waitForElementVisible   findInFilesSelector, 20000
            .click                   findInFilesSelector
            .waitForElementVisible   searchModalSelector, 20000
            .setValue                searchModalSelector + ' input.text', "#{filename}"
            .waitForElementVisible   searchModalSelector + ' .file-item:first-child', 20000
            .click                   searchModalSelector + ' .file-item:first-child'
            .waitForElementVisible   ".kdtabhandle.#{filenameClassname}.active", 20000 # Assertion
            .waitForElementVisible   paneSelector, 20000 # Assertion
            .pause 1, -> next null

      # saveUntitledFile
      (next) ->
        ideHelpers.createAndSaveNewFile browser, user, null, ->
          next null

      # toggleInvisibleFiles
      (next) ->

        fileName     = ".#{helpers.getFakeText().split(' ')[0]}.txt"
        filePath     = "/home/#{user.username}"
        fileSelector = ".file-container span[title='#{filePath}/#{fileName}']"

        helpers.createFileFromMachineHeader(browser, user, fileName, no)
        ideHelpers.clickItemInMachineHeaderMenu(browser, '.refresh')

        browser
          .pause   4000 # wait for file create complete
          .element 'css selector', fileSelector, (result) ->

            if result.status is 0
              ideHelpers.clickItemInMachineHeaderMenu(browser, '.toggle-invisible-files')

              browser
                .waitForElementNotPresent fileSelector, 20000 # Assertion
                .pause 1, -> next null

            else
              ideHelpers.clickItemInMachineHeaderMenu(browser, '.toggle-invisible-files')

              browser
                .waitForElementVisible  fileSelector, 20000 # Assertion
                .pause 1, -> next null

      # openAnExistingFileAndSave
      (next) ->
        oldText  = 'Tests'
        text     = helpers.getFakeText()
        fileName = ideHelpers.createAndSaveNewFile browser, user, oldText, ->

          ideHelpers.closeFile(browser, fileName, user)
          ideHelpers.openAnExistingFile(browser, user, fileName, oldText)

          ideHelpers.setTextToEditor(browser, text)
          browser.assert.containsText    activeEditorSelector, text # Assertion

          # ideHelpers.closeFile(browser, fileName, user)
          ideHelpers.saveFile(browser)
          ideHelpers.closeFile(browser, fileName, user)
          ideHelpers.openAnExistingFile(browser, user, fileName, text)
          browser
            .waitForTextToContain activeEditorSelector, text # Assertion
            .pause 1, -> next null
    ]

    async.series queue

  after: (browser) ->
    browser.end()
