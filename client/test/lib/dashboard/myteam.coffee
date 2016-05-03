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

  searchAndChangeRoleOfTeamMates: (browser) ->

    { invitations, index } = utils.getInvitationData()

    index1 = if index is 0 then 1 else index
    indexOfTargetUser1 = if 1%index1 isnt 0 then 1 else 2
    indexOfTargetUser2 = if 3%index1 isnt 0 then 3 else 4
    indexOfTargetUser3 = if 5%index1 isnt 0 then 5 else 6

    invitations[indexOfTargetUser1].accepted = 'Member'
    invitations[indexOfTargetUser2].accepted = 'Admin'
    invitations[indexOfTargetUser3].accepted = 'Member'
    invitations[index].accepted = 'Owner'

    lastPendingInvitationIndex = 0
    invitations.forEach (invitation, i) ->
      unless invitation.accepted
        lastPendingInvitationIndex = i

    section= '.kdcustomscrollview.HomeAppView--scroller.my-team'
    sectionSelector = '.HomeAppView--section.teammates'
    filterSelector = "#{sectionSelector} .kdinput.text.hitenterview"
    listViewSelector = "#{sectionSelector} .ListView .ListView-row"
    scrollElement = "#{sectionSelector} .ListView"

    user = teamsHelpers.loginTeam browser
    browser
      .url myTeamLink
      .waitForElementVisible section, 2000
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement scrollElement
      .waitForElementVisible selector('role', 1), 20000
      .click selector('role', 1), ->
        myteamhelpers.checkTeammates browser, invitations[0], action(1), action(2), selector('role', 1), no, ->
          browser.waitForElementVisible selector('role', 1), 20000
          browser.click selector('role', 2), ->
            myteamhelpers.checkTeammates browser, invitations[1], action(1), action(2), selector('role', 2), no, ->
              browser.expect.element(selector('role', index+1)).text.to.contain 'Owner'
              browser.click selector('role', lastPendingInvitationIndex+1), ->
                myteamhelpers.checkTeammates browser, invitations[lastPendingInvitationIndex], action(1), action(2), selector('role', lastPendingInvitationIndex+1), yes, ->
                  browser
                    .waitForElementNotPresent selector('fullname', lastPendingInvitationIndex+1), 20000
                    .end()


  sendInvites: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteUser browser, 'member'
    browser.pause 5000
    myteamhelpers.inviteUser browser, 'admin'
    browser.end()


  sendInvitesToAll: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.inviteAll browser
    browser.end()


  checkUploadCSV: (browser) ->

    user = teamsHelpers.loginTeam browser
    browser.url myTeamLink
    myteamhelpers.uploadCSV browser
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


selector = (type, index) ->
  sectionSelector = '.HomeAppView--section.teammates'
  memberSelector = '.kdview.kdlistitemview.kdlistitemview-member'
  "#{sectionSelector} .ListView-row:nth-of-type(#{index}) #{memberSelector} .#{type}"


action = (index) ->
  ".menu-class ul.ButtonWithMenuItemsList li:nth-of-type(#{index})"
