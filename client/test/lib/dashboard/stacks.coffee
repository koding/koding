teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
stackEditorUrl = "#{helpers.getUrl(yes)}/Home/stacks"


module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users =
      targetUser1

    teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
      done()


  redirectStackTemplate: (browser) ->

    sectionSelector = '.kdview.kdtabpaneview.stacks'
    newStackButton = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
    host = utils.getUser()
    url = helpers.getUrl(yes)
    browser.url url, ->
      teamsHelpers.loginToTeam browser, host, no, ->
        browser
          .pause 2000
          .url stackEditorUrl
          .waitForElementVisible sectionSelector, 20000
          .click newStackButton, ->
            helpers.switchBrowser browser, 'Stack-Editor/New'

