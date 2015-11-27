helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'


teamsModalSelector      = '.TeamsModal--groupCreation'
companyNameSelector     = '.login-form input[testpath=company-name]'
sidebarSectionsSelector = '.activity-sidebar .SidebarSections'

module.exports =


  setCookie: (browser) ->

    helpers.setCookie(browser, 'team-access', 'true')


  openTeamsPage: (browser) ->

    teamsSelector = '[testpath=main-header] .full-menu a.teams'

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  teamsSelector, 20000
      .click                  teamsSelector
      .waitForElementVisible  '.content-page.teams', 20000


  fillSignUpFormOnTeamsHomePage: (browser, user) ->

    emailSelector  = '.login-form input[testpath=register-form-email]'
    buttonSelector = 'button[testpath=signup-company-button]'

    browser
      .waitForElementVisible  emailSelector, 20000
      .setValue               emailSelector, user.email
      .waitForElementVisible  companyNameSelector, 20000
      .setValue               companyNameSelector, user.name
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector
      .pause                  2000 # wait for modal change


  enterTeamURL: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[name=slug]', 20000
      .click                  'button[testpath=domain-button]'
      .pause                  2000 # wait for modal change


  enterEmailDomains: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[type=checkbox]', 20000
      .waitForElementVisible  'input[name=domains]', 20000
      .click                  'button[testpath=allowed-domain-button]'
      .pause                  2000 # wait for modal change


  enterInvites: (browser) ->

    inviteeEmail = "inviteuser#{Date.now()}@kd.io"

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[name=invitee1]', 20000
      .setValue               'input[name=invitee1]', inviteeEmail
      .waitForElementVisible  'button[testpath=invite-button]', 2000
      .click                  'button[testpath=invite-button]'
      .pause                  2000 # wait for modal change


  fillUsernamePasswordForm: (browser, user) ->

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[name=username]', 20000
      .clearValue             'input[name=username]'
      .setValue               'input[name=username]', user.username
      .setValue               'input[name=password]', user.password
      .click                  '[testpath=register-button]'
      .pause                  2000 # wait for modal change

    @loginAssertion(browser)


  loginAssertion: (browser) ->

    user = utils.getUser()

    browser
      .waitForElementVisible  '.content-page.welcome', 20000 # Assertion
      .waitForElementVisible  '[testpath=main-sidebar]', 20000 # Assertion

    console.log " ✔ Successfully logged in with username: #{user.username} and password: #{user.password} to team: #{helpers.getUrl(yes)}"


  setupStackPage: (browser) ->

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'button.TeamsModal-button--green', 20000
      .click                  'button.TeamsModal-button--green'
      .pause                  2000 # wait for modal change


  congratulationsPage: (browser) ->

     browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'button span.button-title', 20000
      .click                  'button span.button-title'
      .pause                  2000 # wait for modal change


  loginToTeam: (browser, user) ->

    browser
      .pause                  2000 # wait for login page
      .waitForElementVisible  '.TeamsModal--login', 20000
      .waitForElementVisible  'form.login-form', 20000
      .setValue               'input[name=username]', user.username
      .setValue               'input[name=password]', user.password
      .click                  'button[testpath=login-button]'

    @loginAssertion(browser)


  loginTeam: (browser) ->

    user = utils.getUser()
    url  = helpers.getUrl(yes)

    browser.url url
    browser.maximizeWindow()

    @loginToTeam(browser, user)

    return user


  createInvitation: (browser, user, callback) ->

    adminLink      = '.avatararea-popup a[href="/Admin"]'
    inviteLink     = '.teaminvite.AppModal-navItem'
    teamInvitePage = '.TeamInvite'
    inviteButton   = "#{teamInvitePage} button"
    sendMailPage   = "#{teamInvitePage} .kdscrollview"
    sendMailButton = "#{teamInvitePage} button.green:not(.hidden)"
    notification   = '.kdnotification.main'

    helpers.openAvatarAreaModal(browser)
    browser
      .waitForElementVisible  adminLink, 20000
      .click                  adminLink
      .waitForElementVisible  inviteLink, 20000
      .click                  inviteLink
      .waitForElementVisible  teamInvitePage, 20000
      .setValue               "#{teamInvitePage} textarea.text", user.email
      .waitForElementVisible  inviteButton, 20000
      .click                  inviteButton
      .waitForElementVisible  sendMailPage, 20000
      .assert.containsText    sendMailPage, user.email # Assertion
      .waitForElementVisible  sendMailButton, 20000
      .click                  sendMailButton
      .waitForElementVisible  notification, 20000
      .assert.containsText    notification, 'Invitations sent!'
      .pause                  2000
      .getAttribute           "#{sendMailPage} a" , 'href', (result) ->
        callback result.value


  openTeamSettingsModal: (browser) ->

    avatarareaPopup  = '.avatararea-popup.team'
    teamDashboard    = '.AppModal--admin'
    teamSettingsLink = "#{avatarareaPopup} .admin a"

    browser
      .waitForElementVisible  avatarareaPopup, 20000
      .waitForElementVisible  teamSettingsLink, 20000
      .click                  teamSettingsLink
      .waitForElementVisible  teamDashboard, 20000 # Assertion
      .pause                  200 # Wait for team settings
      .assert.containsText    teamDashboard, 'Team Settings' # Assertion


  seeTeamNameOnsideBar: (browser, name) ->

    sidebarSelector = '.with-sidebar [testpath=main-sidebar]'
    listSelector    = "#{sidebarSelector} .SidebarListItem"

    browser
      .waitForElementVisible  sidebarSelector, 20000
      .waitForElementVisible  listSelector, 20000
      .assert.containsText    sidebarSelector, name


  clickTeamSettings: (browser) ->

    helpers.openAvatarAreaModal(browser, yes)
    @openTeamSettingsModal(browser)


  startStackCreate: (browser) ->

    welcomePageSelector = '.content-page.welcome'
    stackSelector       = "#{welcomePageSelector} a[href='/Admin/Stacks']"
    overlaySelector     = '.AppModal--admin'
    getstartedSelector  = "#{overlaySelector} .stack-onboarding.get-started"
    buttonSelector      = "#{getstartedSelector} .header button"

    browser
      .waitForElementVisible  welcomePageSelector, 20000
      .waitForElementVisible  stackSelector, 20000
      .click                  stackSelector
      .waitForElementVisible  overlaySelector, 20000
      .waitForElementVisible  getstartedSelector, 20000
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector


  openInvitationsTab: (browser) ->

    tabsSelector              = ".kdmodal-content .kdtabhandle-tabs"
    invitationsButtonSelector = "#{tabsSelector} .invitations"
    invitationsPageSelector   = ".kdmodal-content  .AppModal--admin-tabs .invitations"

    browser
      .waitForElementVisible  tabsSelector, 20000
      .waitForElementVisible  "#{tabsSelector} .invitations", 20000
      .waitForElementVisible  invitationsButtonSelector, 20000
      .click                  invitationsButtonSelector
      .waitForElementVisible  invitationsPageSelector, 20000 # Assertion
      .pause                  2000 # wait for page load


  moveToSidebarHeader: (browser, plus, channelHeader) ->

    sidebarSectionsHeaderSelector = "#{sidebarSectionsSelector} .SidebarSection-header"
    channelPlusSelector          = "#{sidebarSectionsHeaderSelector} a[href='/NewChannel']"

    browser
      .waitForElementVisible    sidebarSectionsSelector, 20000
      .moveToElement            sidebarSectionsSelector, 100, 7

    if plus
      browser
        .waitForElementVisible  channelPlusSelector, 20000
        .click                  channelPlusSelector
    else if channelHeader
      browser
        .waitForElementVisible  sidebarSectionsHeaderSelector, 20000
        .click                  sidebarSectionsHeaderSelector


  createChannel: (browser, channelName) ->

    createChannelModalNameSelector   = '.CreateChannel-Modal .CreateChannel-content .channelName input'
    createChannelModalButtonSelector = '.CreateChannel-Modal .Modal-buttons .Button--danger'
    channelName                    or= helpers.getFakeText().split(' ')[0] + Date.now()
    channelLinkOnSidebarSelector     = "#{sidebarSectionsSelector} a[href='/Channels/#{channelName}']"

    @moveToSidebarHeader(browser, yes)

    browser
      .waitForElementVisible  '.CreateChannel-Modal', 20000
      .waitForElementVisible  createChannelModalNameSelector, 20000
      .setValue               createChannelModalNameSelector, channelName
      .waitForElementVisible  createChannelModalButtonSelector, 20000
      .click                  createChannelModalButtonSelector
      .waitForElementVisible  sidebarSectionsSelector, 20000
      .waitForElementVisible  channelLinkOnSidebarSelector, 20000
      .assert.containsText    sidebarSectionsSelector, channelName

    return channelName

