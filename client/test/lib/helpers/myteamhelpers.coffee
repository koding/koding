utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"
welcomeLink    = "#{helpers.getUrl(yes)}/Welcome"
sectionSelector   = '.HomeAppView--section.team-settings'
sectionSendInvites = '.HomeAppView--section.send-invites'
buttonSelector    = "#{sectionSelector} .uploadInputWrapper .HomeAppView--button.custom-link-view"
uploadLogoButton  = "#{buttonSelector}.primary"
removeLogoButton  = "#{buttonSelector}.remove"
teamNameSelector  = "#{sectionSelector} .half input[type=text]"
saveChangesButton = '.HomeAppView--section .HomeAppView--button.fr'

logo = '.HomeAppView--uploadLogo .teamLogo-wrapper'
defaultLogoPath = "#{helpers.getUrl(yes)}/a/images/logos/sidebar_footer_logo.svg"
localImage      = "#{__dirname}/koding.jpeg"
localImage      = require('path').resolve(localImage)
imagePath       = require('path').resolve('sidebar_footer_logo.svg')
teamLogo        = '.HomeAppView--uploadLogo .uploadInputWrapper .kdinput.file'
successMessage  = 'Team settings has been successfully updated.'
executeCommand  = "document.querySelector('.teamLogo').setAttribute('src', 'some_path');"

teammateSection         = '.kdcustomscrollview.HomeAppView--scroller.my-team'
teammateSectionSelector = '.HomeAppView--section.teammates'
checkboxSelector        = '.HomeAppView--section.send-invites .invite-inputs .kdcustomcheckbox'
adminTextSelector       = '.HomeAppView--section.send-invites .information .invite-labels label:last-child span:last-child'
sendInvitesButton       = '.HomeAppView--section.send-invites .custom-link-view.HomeAppView--button.primary.fr'

closeModal           = '.close-icon.closeModal'
welcomeView          = '.WelcomeStacksView'
leaveTeamButton      = '.HomeAppView--button'
passwordSelector     = 'input[name=password]'
forgotPasswordButton = '.kdbutton.cancel'
confirmButton        = 'button[type=submit]'
notification         = '.kdnotification.main'
proceedButton        = '[testpath=proceed]'
mainSideBar          = '.main-sidebar'
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


  # uploadAndRemoveLogo: (browser, callback) ->
  #   aaa = require('path').resolve("#{__dirname}", 'koding.jpeg')
  #   console.log(imagePath);
  #   console.log(aaa)

  #   browser
  #     .waitForElementVisible logo, 20000
  #     .setValue '.HomeAppView--uploadLogo .uploadInputWrapper', aaa


  inviteAndJoinToTeam: (browser, host, callback) ->
    browser
      .url welcomeLink
      .pause 2000
    { invitations, index } = utils.getInvitationData()

    index = if index is 0 then 0 else index
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

    user = utils.getUser no, 1
    lastPendingInvitationIndex = 0
    pendingInvitations = []
    invitations.forEach (invitation, i) ->
      unless invitation.accepted
        if invitation.email isnt user.email
          pendingInvitations.push i
          lastPendingInvitationIndex = i

    browser
      .url myTeamLink
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement "#{teammateSectionSelector} .ListView"
      .waitForElementVisible selector(pendingInvitations[0] + 1), 20000
      .click selector(pendingInvitations[0] + 1), ->
        teamsHelpers.checkTeammates browser, invitations[pendingInvitations[0]], nthItem(1), nthItem(2), selector(1), no, -> #resend invitation
          browser.waitForElementVisible selector(pendingInvitations[0] + 1), 20000
          browser.click selector(indexOfTargetUser1 + 1), ->
            teamsHelpers.checkTeammates browser, invitations[indexOfTargetUser1], nthItem(1), nthItem(2), selector(indexOfTargetUser1 + 1), no, -> #make admin then member
              browser.click selector(indexOfTargetUser2 + 1), -> #make admin
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
                      teamsHelpers.loginToTeam browser, invitations[lastPendingInvitationIndex], yes, 'InvalidUserName', ->
                      browser.assert.containsText notification, 'Unknown user name'
                      teamsHelpers.loginToTeam browser, host , no, '', ->
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
    browser
      .url myTeamLink
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement '.HomeAppView--section.send-invites'
    teamsHelpers.fillInviteInputByIndex browser, 2, invitations[indexOfTargetUser1].email
    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    browser
      .waitForElementVisible '.ContentModal', 20000
      .assert.containsText '.ContentModal.content-modal main', "#{invitations[indexOfTargetUser1].email} is already a member of your team"
      .click proceedButton
    teamsHelpers.clearInviteInputByIndex browser, 2
    browser.pause 2000, callback


  sendAlreadyAdminInvite: (browser, callback) ->
    browser.refresh()
    browser
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement sectionSendInvites
    teamsHelpers.fillInviteInputByIndex browser, 1, invitations[indexOfTargetUser2].email
    browser
      .waitForElementVisible sendInvitesButton, 30000
      .click sendInvitesButton
    browser
      .waitForElementVisible '.ContentModal', 20000
      .assert.containsText '.ContentModal.content-modal header', "You're adding an admin"
      .waitForElementVisible proceedButton, 20000
      .click proceedButton
      .waitForElementVisible '.ContentModal', 20000
      .assert.containsText '.ContentModal.content-modal main', "#{invitations[indexOfTargetUser2].email} is already a member of your team"
      .click proceedButton
    browser.pause 3000, callback


  sendInviteToPendingMember: (browser, callback) ->
    browser.url myTeamLink
    browser
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement sectionSendInvites
    teamsHelpers.inviteUser browser, 'member', invitations[indexOfTargetUser1 + 1].email, no
    browser.pause 1000, callback


  sendNewAdminInvite: (browser, callback) ->
    browser.url myTeamLink
    browser
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement sectionSendInvites
    teamsHelpers.inviteUser browser, 'admin', null, yes
    browser.pause 1000, callback


  sendNewMemberInvite:  (browser, callback) ->
    browser.url myTeamLink
    browser
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement sectionSendInvites
    teamsHelpers.inviteUser browser, 'member', null, yes
    browser.pause 1000, callback


  sendInviteAll: (browser, callback) ->
    teamsHelpers.inviteAll browser
    browser.pause 3000, callback


  #Member can not change team name and team logo
  changeTeamName: (browser, callback) ->

    browser.url myTeamLink
    browser
      .waitForElementVisible sectionSelector, 20000
    targetUser1 = invitations[indexOfTargetUser3]
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, targetUser1 , no, '', ->
        browser
          .waitForElementVisible welcomeView, 60000
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

    targetUser1 = invitations[indexOfTargetUser3]
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
    teamsHelpers.loginToTeam browser, targetUser1 , yes, 'NotAllowedEmail', ->
      browser
        .pause 1000, callback


  checkAdmin: (browser, callback) ->

    user = invitations[indexOfTargetUser2]
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, user, no, '', ->
        browser.pause 2000
        browser.element 'css selector', closeModal, (result) ->
          if result.status is 0
            browser.waitForElementVisible closeModal, 30000
            browser.click closeModal

        browser
          .click '#main-sidebar'
          .waitForElementVisible '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 20000
          .click '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
          .waitForElementVisible '.HomeAppView-Nav--role', 30000
          .assert.containsText '.HomeAppView-Nav--role', 'Admin'
          .pause 1000, callback


  sendInviteToRegisteredUser: (browser, callback) ->
    registeredUser = utils.getUser no, 9
    browser.url myTeamLink
    browser
      .waitForElementVisible sectionSelector, 20000
      .scrollToElement sectionSendInvites
    teamsHelpers.inviteUser browser, 'member', registeredUser.email, yes
    browser.pause 1000, callback


selector = (index) ->
  ".HomeApp-Teammate--ListItem:nth-of-type(#{index}) .dropdown "


nthItem = (index) ->
  ".ButtonWithMenuItemsList li:nth-of-type(#{index})"
