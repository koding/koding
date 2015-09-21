helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'


teamsModalSelector  = '.TeamsModal--groupCreation'
companyNameSelector = '.login-form input[testpath=company-name]'

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

    browser
      .waitForElementVisible  '.content-page.welcome', 20000 # Assertion
      .waitForElementVisible  '[testpath=main-sidebar]', 20000 # Assertion


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

    @setCookie(browser)
    browser.url url

    @loginToTeam(browser, user)

    return user


  openTeamSettingsModal: (browser) ->

    avatarareaPopup      = '.avatararea-popup'
    teamDashboard        = '.AppModal--admin'
    teamSettingsLinkItem = "#{avatarareaPopup} .content a[href='/Admin']"

    browser
      .waitForElementVisible  avatarareaPopup, 20000
      .waitForElementVisible  teamSettingsLinkItem, 20000
      .click                  teamSettingsLinkItem
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

    helpers.openAvatarAreaModal(browser)
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
