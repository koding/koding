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