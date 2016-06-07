utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"

sectionSelector   = '.HomeAppView--section.team-settings'
buttonSelector    = "#{sectionSelector} .uploadInputWrapper .HomeAppView--button.custom-link-view"
uploadLogoButton  = "#{buttonSelector}.primary"
removeLogoButton  = "#{buttonSelector}.remove"
teamNameSelector  = "#{sectionSelector} .half input[type=text]"
saveChangesButton = '.HomeAppView--section .HomeAppView--button.fr'

kodingLogo      = "#{sectionSelector} .HomeAppView--uploadLogo img"
defaultLogoPath = "#{helpers.getUrl(yes)}/a/images/logos/sidebar_footer_logo.svg"
localImage      = "#{__dirname}/upload.png"
localImage      = require('path').resolve(localImage)
teamLogo        = "#{sectionSelector} .kdinput.file"
successMessage  = 'Team settings has been successfully updated.'
executeCommand  = "document.querySelector('.teamLogo').setAttribute('src', 'some_path');"

teammateSection         = '.kdcustomscrollview.HomeAppView--scroller.my-team'
teammateSectionSelector = '.HomeAppView--section.teammates'
checkboxSelector        = '.HomeAppView--section.send-invites .invite-inputs .kdcustomcheckbox'
adminTextSelector       = '.HomeAppView--section.send-invites .information .invite-labels label:last-child span:last-child'
sendInvitesButton       = '.HomeAppView--section.send-invites .custom-link-view.HomeAppView--button.primary.fr'

welcomeView          = '.WelcomeStacksView'
leaveTeamButton      = '.HomeAppView--button'
passwordSelector     = 'input[name=password]'
forgotPasswordButton = '.kdbutton.solid.light-gray'
confirmButton        = 'button[type=submit]'
notification         = '.kdnotification.main'

index              = ''
indexOfTargetUser1 = ''
indexOfTargetUser2 = ''
indexOfTargetUser3 = ''
invitations        = ''

module.exports =

  editTeamName: (browser, host, callback) ->
    browser
      .url myTeamLink
      .pause 3000
      .waitForElementVisible sectionSelector, 20000
      .click saveChangesButton
      .waitForElementNotPresent '.kdnotification', 5000
      .clearValue teamNameSelector
      .setValue teamNameSelector, host.teamSlug + 'new'
      .click saveChangesButton
    teamsHelpers.assertConfirmation browser, successMessage
    browser
      .clearValue teamNameSelector
      .setValue teamNameSelector, host.teamSlug
      .click saveChangesButton
    teamsHelpers.assertConfirmation browser, successMessage
    browser.pause 1000, callback


  inviteAndJoinToTeam: (browser, host, callback) ->
    { invitations, index } = utils.getInvitationData()
    index = if index is 0 then 1 else index
    indexOfTargetUser1 = if 1 % index isnt 0 then 1 else 2
    indexOfTargetUser2 = if 3 % index isnt 0 then 3 else 4
    indexOfTargetUser3 = if 5 % index isnt 0 then 5 else 6

    teamsHelpers.inviteUsers browser, invitations, (res) ->
      teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser1], (res) ->
        teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser2], (res) ->
          teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser3], (res) ->
            browser.pause 1000, callback


  seeTeammatesList: (browser, callback) ->
    browser
      .url myTeamLink
      .pause 2000
      .scrollToElement "#{teammateSectionSelector} .ListView"
      .waitForElementVisible teammateSection, 20000
      .waitForElementVisible teammateSectionSelector, 20000
      .assert.containsText   selector(indexOfTargetUser1 + 1), 'Member'
      .assert.containsText   selector(indexOfTargetUser2 + 1), 'Member'
      .assert.containsText   selector(indexOfTargetUser3 + 1), 'Member'
      .pause 1000, callback


  changeMemberRole: (browser, host, callback) ->
    invitations[indexOfTargetUser1].accepted = 'Member'
    invitations[indexOfTargetUser2].accepted = 'Admin'
    invitations[indexOfTargetUser3].accepted = 'Member'
    invitations[index].accepted = 'Owner'

    lastPendingInvitationIndex = 0
    invitations.forEach (invitation, i) ->
      unless invitation.accepted
        lastPendingInvitationIndex = i
    browser
      .url myTeamLink
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement "#{teammateSectionSelector} .ListView"
      .waitForElementVisible selector(1), 20000
      .click selector(1), ->
        teamsHelpers.checkTeammates browser, invitations[0], nthItem(1), nthItem(2), selector(1), no, ->
          browser.waitForElementVisible selector(1), 20000
          browser.click selector(2), ->
            teamsHelpers.checkTeammates browser, invitations[1], nthItem(1), nthItem(2), selector(2), no, ->
              browser.click selector(indexOfTargetUser2 + 1), ->
                browser
                  .pause 1000
                  .click nthItem(2)
                  .pause 1000
                  .waitForElementVisible selector(indexOfTargetUser2 + 1), 20000
                  .assert.containsText selector(indexOfTargetUser2 + 1), 'Admin'
                  browser.expect.element(selector(index + 1)).text.to.contain 'Owner'
                browser.click selector(lastPendingInvitationIndex + 1), ->
                  browser.waitForElementVisible selector(lastPendingInvitationIndex + 1), 20000
                  teamsHelpers.checkTeammates browser, invitations[lastPendingInvitationIndex], nthItem(1), nthItem(2), selector(lastPendingInvitationIndex + 1), yes, ->
                    teamsHelpers.logoutTeam browser, (res) ->
                      teamsHelpers.loginToTeam browser, invitations[lastPendingInvitationIndex], yes, ->
                      browser.assert.containsText notification, 'Unknown user name'
                      teamsHelpers.loginToTeam browser, host , no, ->
                        browser
                          .waitForElementVisible welcomeView, 20000
                          .url myTeamLink
                          .waitForElementVisible sectionSelector, 20000, callback


  uploadCSV: (browser, callback) ->
    browser
      .url myTeamLink
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement '.HomeAppView--section.send-invites'
    teamsHelpers.uploadCSV browser
    browser.pause 1000, callback


  sendAlreadyMemberInvite: (browser, callback) ->
    teamsHelpers.fillInviteInputByIndex browser, 2, invitations[indexOfTargetUser1].email
    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    teamsHelpers.acceptConfirmModal browser
    teamsHelpers.assertConfirmation browser, "Invitation is sent to #{invitations[indexOfTargetUser1].email}"
    browser.pause 3000, callback


  sendAlreadyAdminInvite: (browser, callback) ->
    teamsHelpers.fillInviteInputByIndex browser, 1, invitations[indexOfTargetUser2].email
    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    teamsHelpers.acceptConfirmModal browser
    teamsHelpers.assertConfirmation browser, "Invitation is sent to #{invitations[indexOfTargetUser2].email}"
    browser.pause 3000, callback


  sendInviteToPendingMember: (browser, callback) ->
    teamsHelpers.inviteUser browser, 'member', invitations[indexOfTargetUser1 + 1]
    browser.pause 3000
    teamsHelpers.inviteUser browser, 'admin',  invitations[indexOfTargetUser2 + 1]
    browser.pause 3000, callback


  sendNewAdminInvite: (browser, callback) ->
    teamsHelpers.inviteUser browser, 'admin'
    browser.pause 3000, callback


  sendNewMemberInvite:  (browser, callback) ->
    teamsHelpers.inviteUser browser, 'member'
    browser.pause 3000, callback


  sendInviteAll: (browser, callback) ->
    teamsHelpers.inviteAll browser
    browser.pause 3000, callback


  sendNewInviteFromResendModal: (browser, callback) ->
    teamsHelpers.newInviteFromResendModal browser, 'member'
    browser.pause 3000
    teamsHelpers.newInviteFromResendModal browser, 'admin'
    browser.pause 1000, callback


  #Member can not change team name and team logo
  changeTeamName: (browser, callback) ->
    targetUser1 = invitations[1]
    teamsHelpers.logoutTeam browser, (res) ->
    teamsHelpers.loginToTeam browser, targetUser1 , no, ->
      browser
        .waitForElementVisible welcomeView, 20000
        .url myTeamLink
        .waitForElementVisible sectionSelector, 20000
        .waitForElementNotPresent checkboxSelector, 20000
        .expect.element(adminTextSelector).text.to.not.contain 'Admin'

      browser
        .scrollToElement "#{teammateSectionSelector} .ListView"
        .waitForElementVisible teammateSection, 20000
        .waitForElementVisible teammateSectionSelector, 20000
        .pause 5000
        .click selector(1)
        .waitForElementNotPresent nthItem(1), 20000
        .scrollToElement sectionSelector
        .waitForElementNotPresent removeLogoButton, 20000
        .waitForElementNotPresent uploadLogoButton, 20000
        .waitForElementNotPresent '.HomeAppView--button .custom-link-view .fr .hidden', 20000
        .assert.attributeEquals teamNameSelector, 'disabled', 'true'
        .pause 1000, callback


  leaveTeam: (browser, callback) ->
    targetUser1 = invitations[1]
    browser
      .waitForElementVisible leaveTeamButton, 20000
      .click leaveTeamButton
      .waitForElementVisible '.kdmodal.kddraggable', 5000

      .click forgotPasswordButton
      .waitForElementVisible  '.kdnotification', 5000
      .assert.containsText    '.kdnotification.main', 'Check your email'
      .pause 5000

      .click leaveTeamButton
      .waitForElementVisible '.kdmodal.kddraggable', 5000
      .clearValue passwordSelector
      .setValue passwordSelector, '1234'
      .click confirmButton
      .waitForElementVisible  '.kdnotification', 20000
      .assert.containsText    '.kdnotification.main', 'Current password cannot be confirmed'
      .pause 5000

      .click leaveTeamButton
      .waitForElementVisible '.kdmodal.kddraggable', 5000
      .clearValue passwordSelector
      .setValue passwordSelector, targetUser1.password
      .click confirmButton
      .assert.urlContains helpers.getUrl(yes)
      .pause 1000, callback


selector = (index) ->
  ".HomeApp-Teammate--ListItem:nth-of-type(#{index}) .dropdown "


nthItem = (index) ->
  ".ButtonWithMenuItemsList li:nth-of-type(#{index})"
