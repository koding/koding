utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
utils = require '../utils/utils.js'
myTeamLink = "#{helpers.getUrl(yes)}/Home/my-team"


module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()

  teamSettings: (browser) ->

    sectionSelector      = '.HomeAppView--section.team-settings'
    welcomeView          = '.WelcomeStacksView'
    buttonSelector       = "#{sectionSelector} .uploadInputWrapper .HomeAppView--button.custom-link-view"
    uploadLogoButton     = "#{buttonSelector}.primary"
    removeLogoButton     = "#{buttonSelector}.remove"
    teamNameSelector     = '.kdinput.text.js-teamName'
    saveChangesButton    = "#{sectionSelector} .HomeAppView--button.custom-link-view.primary.fr"
    leaveTeamButton      = '.HomeAppView--button'
    passwordSelector     = 'input[name=password]'
    forgotPasswordButton = '.kdbutton.solid.light-gray'
    confirmButton        = 'button[type=submit]'

    # kodingLogo = "#{sectionSelector} .HomeAppView--uploadLogo img"
    # defaultLogoPath = "#{helpers.getUrl(yes)}/a/images/logos/sidebar_footer_logo.svg"

    # localImage = "#{__dirname}/upload.png"
    # localImage = require('path').resolve(localImage)

    # teamLogo = "#{sectionSelector} .kdinput.file"
    # successMessage = 'Team settings has been successfully updated.'

    # user = teamsHelpers.loginTeam browser
    # executeCommand = "document.querySelector('.teamLogo').setAttribute('src', 'some_path');"

    targetUser1 = utils.getUser no, 1
    teamsHelpers.logoutTeam browser, (res) ->
      teamsHelpers.loginToTeam browser, targetUser1 , no, ->
        browser.pause 3000
        .pause 3000
        .waitForElementVisible welcomeView, 20000
        .url myTeamLink
        .waitForElementVisible sectionSelector, 20000
        .waitForElementNotPresent removeLogoButton, 2000
        .waitForElementNotPresent uploadLogoButton, 2000
        .waitForElementNotPresent saveChangesButton + ':nth-of-type(1)', 2000
        .assert.attributeEquals teamNameSelector, 'disabled', 'true'
        .waitForElementVisible leaveTeamButton, 20000
        .click leaveTeamButton
        .waitForElementVisible '.kdmodal.kddraggable', 5000
        .pause 2000

      # .click saveChangesButton
      # .waitForElementNotPresent '.kdnotification', 5000
      # .clearValue               teamNameSelector
      # .pause 1000
      # .setValue teamNameSelector, 'random'
      # .click saveChangesButton

    # teamsHelpers.assertConfirmation browser, successMessage
    # browser
    #   .clearValue teamNameSelector
    #   .setValue teamNameSelector, user.teamSlug
    #   .click saveChangesButton

    # teamsHelpers.assertConfirmation browser, successMessage

    # browser.end()


#   inviteAndJoinUsersToTeam: (browser) ->

#     section = '.kdcustomscrollview.HomeAppView--scroller.my-team'
#     sectionSelector = '.HomeAppView--section.teammates'
#     filterSelector = "#{sectionSelector} .kdinput.text.hitenterview"
#     scrollElement = "#{sectionSelector} .ListView"

#     host = teamsHelpers.loginTeam browser
#     { invitations, index } = utils.getInvitationData()
#     index = if index is 0 then 1 else index
#     indexOfTargetUser1 = if 1 % index isnt 0 then 1 else 2
#     indexOfTargetUser2 = if 3 % index isnt 0 then 3 else 4
#     indexOfTargetUser3 = if 5 % index isnt 0 then 5 else 6

#     browser
#       .url myTeamLink, (result) ->
#         if result.status is 0
#           teamsHelpers.inviteUsers browser, invitations, (res) ->
#             teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser1], (res) ->
#               teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser2], (res) ->
#                 teamsHelpers.acceptAndJoinInvitation host, browser, invitations[indexOfTargetUser3], (res) ->
#                   browser
#                     .url myTeamLink
#                     .waitForElementVisible section, 20000
#                     .waitForElementVisible sectionSelector, 20000
#                     .scrollToElement scrollElement
#                     .click selector 'role', indexOfTargetUser1 + 1
#                     .pause 1000
#                     .click nthItem 2
#                     .pause 1000
#                     .click selector 'role', indexOfTargetUser1 + 1
#                     .pause 1000
#                     .click nthItem 2
#                     .pause 1000
#                     .assert.containsText selector('role', indexOfTargetUser1 + 1), 'Member'
#                     .pause 1000
#                     .click selector 'role', indexOfTargetUser2 + 1
#                     .pause 1000
#                     .click nthItem 2
#                     .pause 1000
#                     .assert.containsText selector('role', indexOfTargetUser2 + 1), 'Admin'
#                     .end()

#   searchAndChangeRoleOfTeamMates: (browser) ->

#     { invitations, index } = utils.getInvitationData()

#     index1 = if index is 0 then 1 else index
#     indexOfTargetUser1 = if 1 % index1 isnt 0 then 1 else 2
#     indexOfTargetUser2 = if 3 % index1 isnt 0 then 3 else 4
#     indexOfTargetUser3 = if 5 % index1 isnt 0 then 5 else 6

#     invitations[indexOfTargetUser1].accepted = 'Member'
#     invitations[indexOfTargetUser2].accepted = 'Admin'
#     invitations[indexOfTargetUser3].accepted = 'Member'
#     invitations[index].accepted = 'Owner'

#     lastPendingInvitationIndex = 0
#     invitations.forEach (invitation, i) ->
#       unless invitation.accepted
#         lastPendingInvitationIndex = i

#     section = '.kdcustomscrollview.HomeAppView--scroller.my-team'
#     sectionSelector = '.HomeAppView--section.teammates'
#     filterSelector = "#{sectionSelector} .kdinput.text.hitenterview"
#     listViewSelector = "#{sectionSelector} .ListView .ListView-row"
#     scrollElement = "#{sectionSelector} .ListView"

#     user = teamsHelpers.loginTeam browser
#     browser
#       .url myTeamLink
#       .waitForElementVisible section, 2000
#       .waitForElementVisible sectionSelector, 20000
#       .scrollToElement scrollElement
#       .waitForElementVisible selector('role', 1), 20000
#       .click selector('role', 1), ->
#         teamsHelpers.checkTeammates browser, invitations[0], nthItem(1), nthItem(2), selector('role', 1), no, ->
#           browser.waitForElementVisible selector('role', 1), 20000
#           browser.click selector('role', 2), ->
#             teamsHelpers.checkTeammates browser, invitations[1], nthItem(1), nthItem(2), selector('role', 2), no, ->
#               browser.expect.element(selector('role', index + 1)).text.to.contain 'Owner'
#               browser.click selector('role', lastPendingInvitationIndex + 1), ->
#                 teamsHelpers.checkTeammates browser, invitations[lastPendingInvitationIndex], nthItem(1), nthItem(2), selector('role', lastPendingInvitationIndex + 1), yes, ->
#                   browser
#                     .waitForElementNotPresent selector('fullname', lastPendingInvitationIndex + 1), 20000
#                     .end()


#   sendInvites: (browser) ->

#     user = teamsHelpers.loginTeam browser
#     browser.url myTeamLink
#     teamsHelpers.inviteUser browser, 'member'
#     browser.pause 5000
#     teamsHelpers.inviteUser browser, 'admin'
#     browser.end()


#   sendInvitesToAll: (browser) ->

#     user = teamsHelpers.loginTeam browser
#     browser.url myTeamLink
#     teamsHelpers.inviteAll browser
#     browser.end()


#   checkUploadCSV: (browser) ->

#     user = teamsHelpers.loginTeam browser
#     browser.url myTeamLink
#     teamsHelpers.uploadCSV browser
#     browser.end()


#   resendInvitation: (browser) ->

#     user = teamsHelpers.loginTeam browser
#     browser.url myTeamLink
#     teamsHelpers.resendInvitation browser, 'member'
#     browser.pause 5000
#     teamsHelpers.resendInvitation browser, 'admin'
#     browser.end()


#   newInviteFromResendModal: (browser) ->

#     user = teamsHelpers.loginTeam browser
#     browser.url myTeamLink
#     teamsHelpers.newInviteFromResendModal browser, 'member'
#     browser.pause 5000
#     teamsHelpers.newInviteFromResendModal browser, 'admin'
#     browser.end()


# selector = (type, index) ->
#   sectionSelector = '.HomeAppView--section.teammates'
#   memberSelector = '.kdview.kdlistitemview.kdlistitemview-member'
#   "#{sectionSelector} .ListView-row:nth-of-type(#{index}) #{memberSelector} .#{type}"


# nthItem = (index) ->
#   ".menu-class ul.ButtonWithMenuItemsList li:nth-of-type(#{index})"
