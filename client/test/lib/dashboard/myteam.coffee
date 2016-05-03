utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
utils = require '../utils/utils.js'
myteamhelpers = require '../helpers/myteamhelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"


module.exports =

  teamSettings: (browser) ->

    sectionSelector = '.HomeAppView--section.team-settings'
    buttonSelector = "#{sectionSelector} .uploadInputWrapper .HomeAppView--button.custom-link-view"
    uploadLogoButton = "#{buttonSelector}.primary"
    removeLogoButton = "#{buttonSelector}.remove"
    teamNameSelector = "#{sectionSelector} .half input[type=text]"
    saveChangesButton = "#{sectionSelector} .HomeAppView--ActionBar .HomeAppView--button.custom-link-view.primary.fr"
    kodingLogo = "#{sectionSelector} .HomeAppView--uploadLogo img"
    defaultLogoPath = "#{helpers.getUrl(yes)}/a/images/logos/sidebar_footer_logo.svg"

    localImage = "#{__dirname}/upload.png"
    localImage = require('path').resolve(localImage)

    teamLogo = "#{sectionSelector} .kdinput.file"
    successMessage = 'Team settings has been successfully updated.'

    user = teamsHelpers.loginTeam browser
    executeCommand = "document.querySelector('.teamLogo').setAttribute('src', 'some_path');"

    browser
      .url myTeamLink
      .waitForElementVisible sectionSelector, 20000
      .click saveChangesButton
      .waitForElementNotPresent '.kdnotification', 5000
      .clearValue               teamNameSelector
      .pause 1000
      .setValue teamNameSelector, 'random'
      .click saveChangesButton

    myteamhelpers.assertConfirmation browser, successMessage
    browser
      .clearValue teamNameSelector
      .setValue teamNameSelector, user.teamSlug
      .click saveChangesButton

    myteamhelpers.assertConfirmation browser, successMessage

    browser.end()


  inviteAndJoinUsersToTeam: (browser) ->

    section = '.kdcustomscrollview.HomeAppView--scroller.my-team'
    sectionSelector = '.HomeAppView--section.teammates'
    filterSelector = "#{sectionSelector} .kdinput.text.hitenterview"
    scrollElement = "#{sectionSelector} .ListView"

    host = teamsHelpers.loginTeam browser
    { invitations, index } = utils.getInvitationData()
    index = if index is 0 then 1 else index
    indexOfTargetUser1 = if 1%index isnt 0 then 1 else 2
    indexOfTargetUser2 = if 3%index isnt 0 then 3 else 4
    indexOfTargetUser3 = if 5%index isnt 0 then 5 else 6

    browser
      .url myTeamLink, (result) ->
        if result.status is 0
          myteamhelpers.inviteUsers browser, invitations, (res) ->
            myteamhelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser1], (res) ->
              myteamhelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser2], (res) ->
                myteamhelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser3], (res) ->
                  browser
                    .url myTeamLink
                    .waitForElementVisible section, 20000
                    .waitForElementVisible sectionSelector, 20000
                    .scrollToElement scrollElement
                    .click selector 'role', indexOfTargetUser1+1
                    .pause 1000
                    .click action 2
                    .pause 1000
                    .click selector 'role', indexOfTargetUser1+1
                    .pause 1000
                    .click action 2
                    .pause 1000
                    .assert.containsText selector('role', indexOfTargetUser1+1), 'Member'
                    .pause 1000
                    .click selector 'role', indexOfTargetUser2+1
                    .pause 1000
                    .click action 2
                    .pause 1000
                    .assert.containsText selector('role', indexOfTargetUser2+1), 'Admin'
                    .end()

  sendInvites: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteUser browser
    browser.end()


  sendInvitesToAll: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteAll browser
    browser.end()

  checkUploadCSV: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteUser browser, 'member'
    browser.pause 5000
    myteamhelpers.inviteUser browser, 'admin'
    browser.end()


  resendInvitation: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.resendInvitation browser, 'member'
    browser.pause 5000
    myteamhelpers.resendInvitation browser, 'admin'
    browser.end()

  newInviteFromResendModal: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.newInviteFromResendModal browser, 'member'
    browser.pause 5000
    myteamhelpers.newInviteFromResendModal browser, 'admin'
    browser.end()