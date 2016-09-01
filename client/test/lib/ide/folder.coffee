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

  folder: (browser) ->

    user = utils.getUser()

    queue = [

      # createFolderFromMachineHeader
      (next) ->
        helpers.createFolder browser, user, ->
          next null

      # saveFileToFolder
      (next) ->
        helpers.createFolder browser, user, (result) ->
          helpers.createFile browser, user, 'li.new-file', result.name, null, ->
            next null

      # createFolderFromContextMenu
      (next) ->
        helpers.createFile browser, user, 'li.new-folder', null, null, ->
          next null

      # deleteFolder
      (next) ->
        helpers.createFolder browser, user, (result) ->
          helpers.deleteFile browser, result.selector, ->
            next null

      # terminalFromHereFolder
      (next) ->
        folderName = '.config'
        folderPath = "/home/#{user.username}/#{folderName}"
        terminalTextAssertSelector = '.application-tabview .terminal.active .terminal-pane'

        helpers.openFolderContextMenu(browser, user, folderName)

        browser
          .waitForElementVisible  '.context-list-wrapper .terminal-from-here', 20000
          .click                  '.context-list-wrapper .terminal-from-here'
          .pause 6000 # required for the Connecting...
          .assert.containsText     terminalTextAssertSelector, folderPath # Assertion
          .pause 1, ->
            next null

        # compressFolderZip
        (next) ->
          helpers.createFolder browser, user, (result) ->
            ideHelpers.compressFileFolder browser, user, 'folder', result.name, 'zip', ->
              next null

        # compressFolderTarGz
        (next) ->
          helpers.createFolder browser, user, (result) ->
            ideHelpers.compressFileFolder browser, user, 'folder', result.name, 'targz', ->
              next null
    ]

    async.series queue


  after: (browser) ->
    browser.end()
