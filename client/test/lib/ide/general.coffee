assert  = require 'assert'
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



  general: (browser) ->

    user = utils.getUser()

    queue = [
      # expandCollapseFiletree
      (next) ->
        configPath     = '/home/' + user.username + '/.config'
        configSelector = "span[title='" + configPath + "']"
        file        = "span[title='" + configPath + '/' + 'index.html' + "']"

        helpers.openFolderContextMenu(browser, user, '.config')

        browser
          .waitForElementVisible    '.expand', 20000
          .click                    '.expand'
          .pause                    2000 # required
          .waitForElementVisible    configSelector, 20000
          .click                    configSelector + ' + .chevron'
          .waitForElementVisible    '.collapse', 20000
          .click                    '.collapse'
          .waitForElementNotPresent file, 20000 # Assertion
          .pause 1, -> next null

      # makeTopFolder
      (next) ->
        configPath        = '/home/' + user.username + '/.config'
        filename       = helpers.createFile(browser, user)
        configSelector    = "span[title='" + configPath + "']"
        fileSelector   = "span[title='" + configPath + '/' + filename + "']"
        selectMenuItem = 'li.home' + user.username

        browser
          .waitForElementPresent   fileSelector, 20000 # Assertion
          .waitForElementVisible   configSelector, 10000
          .click                   configSelector
          .click                   configSelector + ' + .chevron'
          .waitForElementVisible   '.make-this-the-top-folder', 20000
          .click                   '.make-this-the-top-folder'
          .waitForElementVisible   '.vm-info', 20000
          .assert.containsText     '.vm-info', '~/.config'
          .waitForElementPresent   fileSelector, 20000 # Assertion

        helpers.openChangeTopFolderMenu(browser)

        browser
          .waitForElementVisible   selectMenuItem, 20000
          .click                   selectMenuItem
          .pause                   2000, -> next null # required

      # openEditorSettings
      (next) ->
        browser
          .waitForElementVisible    '.kdtabhandle-tabs .settings', 20000
          .waitForElementVisible    '.kdlistview-default.expanded', 50000
          .click                    '.kdtabhandle-tabs .settings'
          .waitForElementVisible    '.settings-pane .settings-header:first-child', 20000 # Assertion
          .pause 1, -> next null

      # enterFullScreen
      (next) ->
        browser
          .waitForElementVisible    '.kdtabhandle-tabs .files', 20000
          .click                    '.kdtabhandle-tabs .files'
          .waitForElementVisible    '.kdlistview-default.expanded', 50000
          .waitForElementVisible     '.panel-1 .panel-0 .application-tab-handle-holder', 20000
          .click                     '.panel-1 .panel-0 .application-tab-handle-holder .plus'
          .waitForElementVisible     '.context-list-wrapper', 20000
          .click                     '.context-list-wrapper li.enter-fullscreen'
          .waitForElementVisible     '.ws-tabview.fullscreen', 20000 # Assertion
          .pause 1, -> next null

    ]

    async.series queue

  after: (browser) -> browser.end()
