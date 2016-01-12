utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()


  inviteUserAndRejectInvitation: (browser) ->

    host                   = utils.getUser no, 0
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant            = utils.getUser no, 1
    secondUserName         = participant.username
    secondUserAvatar       = ".avatars .avatarview[href='/#{secondUserName}']"
    secondUserOnlineAvatar = secondUserAvatar + '.online'

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser
        collaborationHelpers.startSessionAndInviteUser(browser, host, participant, no)
        browser
          .waitForElementNotPresent secondUserAvatar, 60000
          .waitForElementNotPresent secondUserOnlineAvatar, 50000 # Assertion

        collaborationHelpers.endSessionFromStatusBar(browser)
      else
        collaborationHelpers.rejectInvitation(browser)

      browser.end()