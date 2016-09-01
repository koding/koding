helpers    = require '../helpers/helpers.js'
ideHelpers = require '../helpers/idehelpers.js'
utils = require '../utils/utils.js'
async = require 'async'
teamsHelpers = require '../helpers/teamshelpers.js'

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


  file: (browser, done) ->
    user = utils.getUser()

    queue = [

      # createFileFromContextMenu
      (next) ->
        helpers.createFile browser, user, null, null, null, (res) -> next null

      # createFileFromMachineHeader
      (next) ->
        helpers.createFileFromMachineHeader browser, user, null, yes, (res) ->
          next null

      # deleteFile
      (next) ->
        filename     = helpers.createFile(browser, user)
        configPath      = '/home/' + user.username + '/.config'
        fileSelector = "span[title='" + configPath + '/' + filename + "']"
        helpers.deleteFile browser, fileSelector, -> next null

      # rename file
      (next) ->
        filename     = helpers.createFile(browser, user)
        configPath      = '/home/' + user.username + '/.config'
        fileSelector = "span[title='" + configPath + '/' + filename + "']"

        paragraph        = helpers.getFakeText()
        newFileName      = paragraph.split(' ')[0] + '.txt'
        newFileSelector  = "span[title='" + configPath + '/' + newFileName + "']"

        browser
          .waitForElementPresent     fileSelector, 20000
          .click                     fileSelector
          .click                     fileSelector + ' + .chevron'
          .waitForElementVisible     'li.rename', 20000
          .click                     'li.rename'
          .waitForElementVisible     'li.selected .rename-container .hitenterview', 20000
          .clearValue                'li.selected .rename-container .hitenterview'
          .setValue                  'li.selected .rename-container .hitenterview', newFileName + '\n'
          .waitForElementPresent     newFileSelector, 20000
          .pause 10, -> next null # Assertion


      # duplicateFile
      (next) ->
        filename      = helpers.createFile(browser, user)
        newFileName   = filename.split('.txt').join('_1.txt')
        configPath       = '/home/' + user.username + '/.config'
        fileSelector  = "span[title='" + configPath + '/' + filename + "']"
        newFile       = "span[title='" + configPath + '/' + newFileName + "']"

        browser
          .waitForElementPresent     fileSelector, 20000
          .click                     fileSelector
          .click                     fileSelector + ' + .chevron'
          .waitForElementPresent     'li.duplicate', 20000
          .click                     'li.duplicate'
          .pause                     2000
          .waitForElementPresent     newFile, 20000 # Assertion

        helpers.deleteFile browser, fileSelector, ->
          helpers.deleteFile browser, newFile, -> next null

      # createFileAndOpen
      (next) ->
        fileName = helpers.createFile browser, user, null, null, null, (res) ->
          ideHelpers.openFile browser, user, fileName, -> next null

      # compressFileZip
      (next) ->
        fileName = helpers.createFile browser, user, null, null, null, (res) ->
          ideHelpers.compressFileFolder browser, user, 'file', fileName, 'zip', -> next null

      # compressFileTarGz
      (next) ->
        fileName = helpers.createFile browser, user, null, null, null, (res) ->
          ideHelpers.compressFileFolder browser, user, 'file', fileName, 'targz', -> next null

       # drag drop file will be implemented
      # (next) ->
      #   fileName = helpers.createFile browser, user, null, null, null, (res) ->
      #     ideHelpers.dragDropFile browser, 'fileName', -> next null
    ]

    async.series queue

  after: (browser) -> browser.end()
