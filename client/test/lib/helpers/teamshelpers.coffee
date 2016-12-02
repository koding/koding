helpers                  = require '../helpers/helpers.js'
utils                    = require '../utils/utils.js'
async                    = require 'async'
path                     = require 'path'
awsKeyPath               = path.resolve __dirname, '../../../../../vault/config/aws/worker_ci_test_key.json'
awsKey                   = require awsKeyPath
teamsModalSelector       = '.TeamsModal--groupCreation'
companyNameSelector      = '.login-form input[testpath=company-name]'
sidebarSectionsSelector  = '.activity-sidebar .SidebarChannelsSection'
chatItem                 = '.Pane-body .ChatList .ChatItem'
chatInputSelector        = '.ChatPaneFooter .ChatInputWidget textarea'
invitationsModalSelector = '.kdmodal-content  .AppModal--admin-tabs .invitations'
pendingMembersTab        = "#{invitationsModalSelector} .kdtabhandle.pending-invitations"
pendingMemberView        = "#{invitationsModalSelector} .kdlistitemview-member.pending"
teamsLoginModal          = '.TeamsModal--login'
stackCatalogModal        = '.StackCatalogModal'
sidebarSelector          = '.activity-sidebar .SidebarTeamSection'
sidebarStackSection      = "#{sidebarSelector} .SidebarStackSection.active"
stackMachineItem         = "#{sidebarStackSection} .SidebarMachinesListItem"
stackMachine             = "#{stackMachineItem}.Running.active"
stackTemplateList        = "#{stackCatalogModal} .stack-template-list"
stackModalCloseButton    = '.StackCatalogModal .close-icon'
envMachineStateModal     = '.env-machine-state.env-modal'
stackSettingsMenuIcon    = '.stacktemplates .stack-template-list .stack-settings-menu .chevron'
myStackTemplatesButton   = '.kdview.kdtabhandle-tabs .my-stack-templates'
closeButton              = "#{stackCatalogModal} .kdmodal-inner .closeModal"
closeModal               = '.close-icon.closeModal'
visibleStack             = '[testpath=StackEditor-isVisible]'
#Team Creation
modalSelector            = '.TeamsModal.TeamsModal--create'
emailSelector            = "#{modalSelector} input[name=email]"
companyNameSelector      = "#{modalSelector} input[name=companyName]"
signUpButton             = "#{modalSelector} button[type=submit]"
teamsModalSelector       = '.TeamsModal--groupCreation'
doneButton               = "#{teamsModalSelector} button.TeamsModal-button"
usernameInput            = "#{teamsModalSelector} input[name=username]"
passwordInput            = "#{teamsModalSelector} input[name=password]"
errorMessage             = '.kdnotification.main'
teamCreateLink           = "a[href='/Teams/Create']"
userInfoErrorMsg         = '.validation-error .kdview.wrapper'
alreadyMemberModal       = "#{teamsModalSelector}.alreadyMember"
proceedButton            = '[testpath=proceed]'
url                      = helpers.getUrl()
logoutUrl  = "#{helpers.getUrl(yes)}/logout"

KONFIG = require 'koding-config-manager'

module.exports =
  enterTeamURL: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  '.TeamsModal--domain', 20000
      .waitForElementVisible  'input[name=slug]', 20000
      .click                  'button[testpath=domain-button]'


  fillUsernamePasswordForm: (browser, user, invalidCredential = no, invalidInfo) ->
    browser
      .waitForElementVisible   teamsModalSelector, 20000
    if invalidCredential
      switch invalidInfo
        when 'InvalidUserName'
          browser
            .waitForElementVisible  usernameInput, 20000
            .clearValue             usernameInput
            .setValue               usernameInput, 'abc'
            .setValue               passwordInput, user.password
            .click                  doneButton
            .waitForElementVisible  userInfoErrorMsg, 20000
            .assert.containsText    userInfoErrorMsg, 'Username should be between 4 and 25 characters!'

        when 'SameDomainAndUserName'
          browser
            .waitForElementVisible  usernameInput, 20000
            .clearValue             usernameInput
            .setValue               usernameInput, user.teamSlug
            .setValue               passwordInput, user.password
            .click                  doneButton
            .waitForElementVisible  errorMessage, 20000
            .assert.containsText    errorMessage, 'Sorry, your group domain and your username can not be the same!'

        when 'AlreadyRegisteredUserName'
          browser
            .waitForElementVisible  usernameInput, 20000
            .clearValue             usernameInput
            .setValue               usernameInput, user.username
            .setValue               passwordInput, user.password
            .click                  doneButton
            .waitForElementVisible  errorMessage, 20000
            .assert.containsText    errorMessage, "Sorry, \"#{user.username}\" is already taken!"

        when 'ShortPassword'
          browser
            .waitForElementVisible  usernameInput, 20000
            .clearValue             usernameInput
            .setValue               usernameInput, user.username
            .setValue               passwordInput, '123'
            .click                  doneButton
            .waitForElementVisible  userInfoErrorMsg, 20000
            .assert.containsText    userInfoErrorMsg, 'Passwords should be at least 8 characters.'


    else
      browser
        .element 'css selector', alreadyMemberModal, (result) =>
          if result.status is 0
            browser
              .waitForElementVisible    passwordInput, 20000
              .setValue                 passwordInput, user.password
          else
            browser
              .waitForElementVisible  usernameInput, 20000
              .clearValue             usernameInput
              .setValue               usernameInput, user.username
              .setValue               passwordInput, user.password

          browser
            .click doneButton
            .pause 2000 # wait for modal change

          @loginAssertion(browser)


  loginAssertion: (browser, callback) ->

    user = utils.getUser()

    browser
      .waitForElementVisible  '[testpath=main-sidebar]', 20000, yes, callback # Assertion

    console.log " ✔ Successfully logged in with username: #{user.username} and password: #{user.password} to team: #{helpers.getUrl(yes)}"


  loginToTeam: (browser, user, invalidCredentials = no, invalidInfo, callback = -> ) ->

    incorrectEmailAddress = 'a@b.com'
    incorrectUserName     = 'testUserName'
    wrongPassword         = 'password'
    unrecognizedMessage   = 'Unrecognized email'
    unknownUserMessage    = 'Unknown user name'
    wrongPasswordMessage  = 'Access denied'
    inputUserName         = 'input[name=username]'
    inputPassword         = 'input[name=password]'
    loginButton           = 'button[testpath=login-button]'
    notification          = '.kdnotification.main'

    browser
      .pause                  2000 # wait for login page
      .waitForElementVisible  '.TeamsModal--login', 20000
      .waitForElementVisible  'form.login-form', 20000

    if invalidCredentials
      browser
        .clearValue           'input[name=username]'
        .clearValue           'input[name=password]'
      switch invalidInfo
        when 'InvalidUserName'
          browser
            .setValue               'input[name=username]', user.username + 'test'
            .setValue               'input[name=password]', user.password
            .click                  'button[testpath=login-button]'
            .waitForElementVisible  notification, 20000
            .assert.containsText    notification, 'Unknown user name'

        when 'InvalidPassword'
          browser
            .setValue                'input[name=username]', user.username
            .setValue                'input[name=password]', user.password + 'wrong'
            .click                   'button[testpath=login-button]'
            .waitForElementVisible   notification, 20000
            .assert.containsText     notification, 'Access denied!'

        when 'NotAllowedEmail'
          email = 'kodingtestuser@koding.com'
          browser
            .setValue               'input[name=username]', email
            .setValue               'input[name=password]', user.password
            .click                  'button[testpath=login-button]'
            .waitForElementVisible  notification, 20000
            .assert.containsText    notification, 'Unrecognized email'

    else
      browser
        .clearValue   'input[name=username]'
        .clearValue   'input[name=password]'
        .setValue     'input[name=username]', user.username
        .setValue     'input[name=password]', user.password
        .click        'button[testpath=login-button]', => @loginAssertion browser, callback


  loginTeam: (browser, user, invalidCredentials = no, invalidInfo, callback = -> ) ->

    user               ?= utils.getUser()
    url                = "http://#{user.teamSlug}.#{KONFIG.domains.base}:#{KONFIG.publicPort}"
    inviteLink         = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"
    teamsLogin         = '.TeamsModal--login'
    stackCatalogModal  = '.StackCatalogModal'
    stackCloseButton   = "#{stackCatalogModal} .kdmodal-inner .closeModal"

    browser.url url
    browser.maximizeWindow()
    browser.pause  3000
    browser.element 'css selector', teamsLogin, (result) =>
      if result.status is 0
        @loginToTeam browser, user, invalidCredentials, invalidInfo
      else
        @createTeam browser, user, inviteLink, invalidInfo

      browser.pause 3000
      browser.element 'css selector', stackCatalogModal, (result) ->
        if result.status is 0
          browser
            .waitForElementVisible  stackCatalogModal, 20000
            .waitForElementVisible  stackCloseButton, 20000
            .click                  stackCloseButton
      callback user
    return user


  checkForgotPassword: (browser, user, callback) ->
    usernameModalSelector   = '.kdview.kdtabpaneview.username'
    sectionSelector         = "#{usernameModalSelector} section"
    browser
      .waitForElementVisible usernameModalSelector, 20000
      .click                 '.TeamsModal-button-link a'
      .pause                 2000
      .waitForElementVisible usernameModalSelector, 20000
      .pause                 2000
      .click                 '.TeamsModal-button-link a'
      .pause                 2000


  fillTeamSignUp: (browser, email, teamSlug) ->
    browser
      .waitForElementVisible  modalSelector, 20000
      .waitForElementVisible  emailSelector, 20000
      .waitForElementVisible  companyNameSelector, 20000
      .clearValue             emailSelector
      .setValue               emailSelector, email
      .pause                  2000
      .setValue               companyNameSelector, teamSlug
      .click                  signUpButton
      .pause                  2500


  createTeam: (browser, user, inviteOrCreateLink, invalidInfo, callback) ->
    inviteLink               = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"
    createLink               = "#{helpers.getUrl()}/Teams/Create"

    if inviteOrCreateLink is inviteLink
      browser.url  inviteOrCreateLink
      browser.maximizeWindow()
      @fillTeamSignUp(browser, user.email, user.teamSlug)
      @enterTeamURL(browser)
      @checkForgotPassword(browser)
      @fillUsernamePasswordForm(browser, user)

    else
      browser
        .url url
        .maximizeWindow()
        .waitForElementVisible teamCreateLink, 20000
        .click teamCreateLink

      switch invalidInfo
        when 'InvalidEmail'
          @fillTeamSignUp(browser, user.email + '***', user.teamSlug)
          browser
            .waitForElementVisible userInfoErrorMsg, 20000
            .assert.containsText   userInfoErrorMsg, 'Please type a valid email address.'

        when 'InvalidTeamUrl'
          @fillTeamSignUp(browser, user.email, 'test')
          @enterTeamURL(browser)
          browser
            .waitForElementVisible errorMessage, 5000
            .assert.containsText   errorMessage, 'Invalid domain!'

        when 'EmptyTeamUrl'
          @fillTeamSignUp(browser, user.email, '')
          browser
            .waitForElementVisible  userInfoErrorMsg, 20000
            .assert.containsText    userInfoErrorMsg, 'Please enter a team name.'
          @fillTeamSignUp(browser, user.email, user.teamSlug)
          browser
            .waitForElementVisible  'input[name=slug]', 20000
            .clearValue             'input[name=slug]'
            .setValue               'input[name=slug]', ''
            .click                  'button[testpath=domain-button]'
            .waitForElementVisible  errorMessage, 20000
            .assert.containsText   errorMessage, 'Domain name should be longer than 2 characters!'

        when 'UpperCaseTeamUrl'
          @fillTeamSignUp(browser, user.email, 'KodingTest')
          browser.waitForElementVisible  'input[name=slug]', 20000
          browser.getValue 'input[name=slug]', (result) ->
            browser.assert.equal result.value, 'kodingtest'

        when 'AlreadyUsedTeamUrl'
          @fillTeamSignUp(browser, user.email, 'koding')
          @enterTeamURL(browser)
          browser
            .waitForElementVisible errorMessage, 5000
            .assert.containsText   errorMessage, 'Domain is taken!'

        when 'InvalidUserName'
          @fillTeamSignUp(browser, user.email, user.teamSlug)
          @enterTeamURL(browser)
          @checkForgotPassword(browser)
          @fillUsernamePasswordForm(browser, user, yes, invalidInfo)

        when 'SameDomainAndUserName'
          @fillTeamSignUp(browser, user.email, user.teamSlug)
          @enterTeamURL(browser)
          @checkForgotPassword(browser)
          @fillUsernamePasswordForm(browser, user, yes, invalidInfo)

        when 'AlreadyRegisteredUserName'
          @fillTeamSignUp(browser, user.email + 'test', user.teamSlug + 'test')
          @enterTeamURL(browser)
          @fillUsernamePasswordForm(browser, user, yes, invalidInfo)

        when 'ShortPassword'
          @fillTeamSignUp(browser, user.email, user.teamSlug)
          @enterTeamURL(browser)
          @fillUsernamePasswordForm(browser, user, yes, invalidInfo)

        when 'InvalidPassword'
          @fillTeamSignUp(browser, user.email, user.teamSlug)
          @enterTeamURL(browser)
          @fillUsernamePasswordForm(browser, user, yes, invalidInfo)



  moveToSidebarHeader: (browser, plus, channelHeader) ->

    sidebarSectionsHeaderSelector = "#{sidebarSectionsSelector} .SidebarSection-header"
    channelPlusSelector           = "#{sidebarSectionsHeaderSelector} a[href='/NewChannel']"

    browser
      .pause                   7500 # wait for load to sidebar
      .waitForElementVisible   sidebarSectionsSelector, 20000
      .moveToElement           sidebarSectionsHeaderSelector, 100, 7

    if plus
      browser
        .moveToElement          channelPlusSelector, 8, 5
        .waitForElementVisible  channelPlusSelector, 20000
        .click                  channelPlusSelector
    else if channelHeader
      browser.click             sidebarSectionsHeaderSelector


  createCredential: (browser, provider, credentialName, addMore = no, done) ->

    url = helpers.getUrl(yes)

    stacksPageSelector = '.HomeAppView-Stacks--create'
    newStackButton = "#{stacksPageSelector} .kdbutton.GenericButton.HomeAppView-Stacks--createButton"
    providers = '.providers.box-wrapper'
    providerSelector = "#{providers} .provider.box.#{provider}"
    skipGuideButton = '.kdview.stack-onboarding.main-content a.custom-link-view.HomeAppView--button'
    stackEditorTab = "#{visibleStack} .kdview.kdtabview.StackEditorTabs"
    credentialsTabSelector = "#{stackEditorTab} div.kdtabhandle.credentials.notification"
    checkForCredentials = ".kdview.kdlistitemview.kdlistitemview-default.StackEditor-CredentialItem.#{provider}"
    createNewButton = '.kdview.stacks.step-creds .kdbutton.add-big-btn.with-icon'


    browser
      .url "#{url}/Home/stacks"
      .waitForElementVisible stacksPageSelector, 20000
      .click newStackButton
      .pause 1000
      .waitForElementVisible providers, 20000
      .click providerSelector
      .waitForElementVisible skipGuideButton, 20000
      .click skipGuideButton
      .pause 1000
      .waitForElementVisible stackEditorTab, 20000
      .click credentialsTabSelector
    browser.element 'css selector', checkForCredentials, (result) =>
      if result.status is -1
        @fillCredentialsPage browser, credentialName, done
      else
        if addMore
          browser
            .waitForElementVisible createNewButton, 20000
            .click createNewButton
            .pause 1000, =>
              @fillCredentialsPage browser, credentialName, done
        else
          done()


  fillCredentialsPage: (browser, name, done) ->

    newCredentialPage = '.kdview.stacks.stacks-v2'
    saveButton = "#{newCredentialPage} button[type=submit]"
    regionSelector = '.kdview.formline.region .kdselectbox select'
    eu_west_1 = "#{regionSelector} option[value=us-west-1]"

    { accessKeyId, secretAccessKey } = @getAwsKey()

    browser
      .waitForElementVisible newCredentialPage, 20000
      .scrollToElement saveButton
      .setValue "#{newCredentialPage} .title input", name
      .pause 200
      .setValue "#{newCredentialPage} .access-key input", accessKeyId
      .pause 200
      .setValue "#{newCredentialPage} .secret-key input", secretAccessKey
      .pause 200
      .click regionSelector
      .pause 200
      .waitForElementVisible eu_west_1, 20000
      .click eu_west_1
      .pause 200
      .click "#{newCredentialPage} .title input"
      .pause 200
      .click saveButton
      .pause 1000, -> done()


  buildStack: (browser, done) ->
    sidebarSelector = '.SidebarTeamSection'
    buildStackModal = '.kdmodal.env-modal.env-machine-state.kddraggable.has-readme'
    buildStackButton = "#{buildStackModal} .kdbutton.turn-on.state-button.solid.green.medium.with-icon"
    progressBarSelector = "#{buildStackModal} .progressbar-container"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"
    menuSelector   = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
    draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft'
    defaultStackSelector = '.SidebarTeamSection .SidebarStackSection.draft.active'
    closeButton = '.ContentModal.kdmodal .kdmodal-inner .close-icon'

    browser
      .pause 2000
      .click '#main-sidebar'
      .waitForElementVisible sidebarSelector, 20000

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is -1
        @createCredential browser, 'aws', 'build-stack', no, (res) =>
          @createStack browser, 'TeamStack', yes, (res) =>
            browser.pause 3000, =>
              @buildStackFlow browser, ->
                done()
      else
        @buildStackFlow browser, ->
          done()


  buildStackFlow: (browser, done) ->
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"
    browser.getAttribute vmSelector, 'title', (result) =>
      status = result.value.substring 16
      switch status
        when 'NotInitialized' then @turnOnVm browser, yes, done
        when 'Running' then done()
        when 'Stopping' then @waitUntilVmStopping browser, done
        when 'Stopped' then @turnOnVm browser, no, done
        when 'Starting' then @waitUntilVmRunning browser, done

  turnOnVm: (browser, firstBuild = no, done = -> ) ->
    credentialSelector = '.kdselectbox'
    credential = "#{credentialSelector} option[text='test credential']"
    buttonSelector = '.resource-state-modal.kdmodal .build-stack-flow footer .GenericButton'

    browser
      .waitForElementVisible '.kdview', 20000
      .pause 2000
      .waitForElementVisible buttonSelector + ':nth-of-type(2)', 20000
      .click buttonSelector + ':nth-of-type(2)'
      .waitForElementVisible '.resource-state-modal.kdmodal .credentials-page .credential-form', 20000

    browser.getValue credentialSelector, (result) ->
      if result.value is ''
        browser
          .click credentialSelector
          .pause 200
          .waitForElementVisible credential, 20000
          .click credential
          .pause 200

    browser
      .click buttonSelector
      .waitForElementVisible '.BaseModalView.kdmodal section.main .progressbar-container', 20000
      .waitForElementVisible '.kdview.kdscrollview', 20000
      .waitForElementVisible '.kdview.jtreeview.expanded', 20000
      .assert.containsText   'body.ide .kdlistitemview-finderitem > div .title', 'Applications'
    @waitUntilVmRunning browser, =>
      browser.pause 6000, =>
        @waitStartCoding browser, ->
          done()

  waitStartCoding: (browser, done) ->
    buttonSelector = '.resource-state-modal.kdmodal .build-stack-flow footer .GenericButton'

    browser.element 'css selector', buttonSelector + ':nth-of-type(2)', (result) ->
      if result.status is 0
        browser.waitForElementVisible buttonSelector + ':nth-of-type(2)', 20000
        browser.click buttonSelector + ':nth-of-type(2)'
        done()
      else
        @waitStartCoding browser, done

  waitUntilVmStopping: (browser, done) ->

    sidebarSelector = '.SidebarTeamSection'
    sidebarStackSection = "#{sidebarSelector} .SidebarSection-body"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"

    browser
      .pause 10000
      .getAttribute vmSelector, 'title', (result) =>
        if result.value.substring(16) is 'Stopped'
          console.log '   VM is stopped'
          done()
        else
          console.log '   VM is still stopping'
          @waitUntilVmStopping browser, done


  waitUntilVmRunning: (browser, done) ->
    sidebarSelector = '.SidebarTeamSection'
    sidebarStackSection = "#{sidebarSelector} .SidebarSection-body"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"

    browser
      .getAttribute vmSelector, 'title', (result) =>
        if result.value.substring(16) is 'Running'
          console.log '   VM is running'
          browser.pause 2000
          done()
        else
          console.log '   VM is still building'
          @waitUntilVmRunning browser, done


  createPrivateStack: (browser, done) ->
    @createCredential browser, 'aws', 'private-stack', no, (res) =>
      @createStack browser, 'PrivateStack', no, (res) =>
        @initializeStack browser, ->
          done()


  createDefaultStackTemplate: (browser, done) ->
    @createCredential browser, 'aws', 'draft-stack', yes, (res) =>
      @createStack browser, 'DefaultStack', no, (res) ->
        done()


  createStack: (browser, stackName, teamStack = no, done) ->

    visibleStack = '[testpath=StackEditor-isVisible]'
    stackEditorHeader = "#{visibleStack} .StackEditorView--header"
    useThisAndContinueButton = '.StackEditor-CredentialItem--buttons .kdbutton.solid.compact.outline.verify'
    editorPaneSelector = "#{visibleStack} .kdview.pane.editor-pane.editor-view"
    stackTemplateNameArea = "#{stackEditorHeader} .kdinput.text.template-title.autogrow"
    saveButtonSelector = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
    successModal = '.kdmodal-inner .kdmodal-content'
    closeButton = '.ContentModal.kdmodal .kdmodal-inner .close-icon'
    shareButton  = '[testpath=proceed]'
    vmSelector   = '.SidebarMachinesListItem cite'

    browser.pause 1000, =>
      browser
        .waitForElementVisible useThisAndContinueButton, 30000
        .click useThisAndContinueButton
        .waitForElementVisible editorPaneSelector, 20000
        .waitForElementVisible stackTemplateNameArea, 2000
        .setValue stackTemplateNameArea, ''
        .pause 1000
        .setValue stackTemplateNameArea, stackName
        .click saveButtonSelector, =>
          browser.element 'css selector', vmSelector, (result) =>
            if result.status is 0
              @waitUntilToSavePrivateStack browser, ->
                done()
            else
              @waitUntilToCreateStack browser, ->
                if teamStack
                  browser
                    .waitForElementVisible '.StackEditor-ShareModal.kdmodal footer', 20000
                    .click shareButton
                    .waitForElementVisible '.ContentModal.content-modal main', 20000
                    .click shareButton, ->
                      done()
                else
                  browser.click closeButton, ->
                    done()


  waitUntilToSavePrivateStack: (browser, done) ->
    browser.elements 'css selector', '.kdbutton.GenericButton.save-test.w-loader.loading', (result) =>
      if result.value.length > 0
        @waitUntilToSavePrivateStack browser, done
      else
        browser.pause 1000, done


  waitUntilToCreateStack: (browser, done) ->
    successModal          = '.kdmodal-inner .kdmodal-content'
    closeButton           = '.ContentModal.kdmodal .kdmodal-inner .close-icon'
    browser.element 'css selector', successModal, (result) =>
      browser.pause 2000
      if result.status is 0
        browser.waitForElementVisible successModal, 20000
        browser.waitForElementVisible closeButton,  20000, done
      else @waitUntilToCreateStack browser, done


  initializeStack: (browser, done) ->
    draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft:last-child'
    menuSelector         = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
    browser
      .click '#main-sidebar'
      .waitForElementVisible draftStackHeader, 20000
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 3000
      .click  "#{menuSelector}:nth-of-type(2)"
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'Stack generated successfully'
      .pause 1000, done


  getAwsKey: -> return awsKey


  fillJoinForm: (browser, userData, assertLoggedIn = yes, callback = -> ) ->

    loginForm     = '.TeamsModal.TeamsModal--groupCreation.join'
    emailInput    = "#{loginForm} input[name=email]"
    usernameInput = "#{loginForm} input[name=username]"
    passwordInput = "#{loginForm} input[name=password]"
    joinButton    = "#{loginForm} .TeamsModal-button--green"

    browser
      .waitForElementVisible loginForm, 20000
      .waitForElementVisible emailInput, 20000
      .waitForElementVisible usernameInput, 20000
      .waitForElementVisible passwordInput, 20000
      .waitForElementVisible joinButton, 20000
      .setValue              usernameInput, userData.username
      .setValue              passwordInput, userData.password
      .click                 joinButton

    if assertLoggedIn
      @loginAssertion(browser, callback)


  getInvitationUrl: (browser, email, callback) ->

    fn = (email, done) ->
      options  =
        query  : email
        status : 'pending'

      _remote.api.JInvitation.search options, {}, (err, invitations) ->
        done { err, invitation: invitations[0] }

    browser
      .timeoutsAsyncScript 10000
      .executeAsync fn, [ email ], (result) ->
        { status, value } = result

        if status is -1 or value.err or not value.invitation
          helpers.notifyTestFailure browser, 'inviteUserAndJoinTeam'

        teamUrl       = helpers.getUrl yes
        invitationUrl = "#{teamUrl}/Invitation/#{value.invitation.code}"

        callback invitationUrl

  logoutTeamfromUrl: (browser, callback) ->
    browser.url logoutUrl, ->
      callback()


  closeModal: (browser, done) ->
    browser.element 'css selector', closeModal, (result) =>
      if result.status is 0
        browser.waitForElementVisible closeModal, 30000
        browser.click closeModal
        browser.pause 1000, done
      else
        @closeModal browser, done

  logoutTeam: (browser, callback) ->

    @closeModal browser, ->
      browser
        .waitForElementVisible '#main-sidebar', 30000
        .waitForElementVisible '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 20000
        .click '.Sidebar-logo-wrapper'
        .click '#main-sidebar'
        .moveToElement '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 0, 0
        .click '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
        .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistview-contextmenu.default', 40000
        .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default', 20000
        .click '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default:nth-of-type(5)'
        .pause 2000, -> callback()

  inviteAndJoinWithUsers: (browser, users, callback) ->
    host = @loginTeam browser
    browser.pause 5000, =>

      queue = [
        (next) =>
          @inviteUsers browser, users, ->
            next null, host
        (next) =>
          users.map (user) =>
            @acceptAndJoinInvitation host, browser, user, (res) ->
              next null, user
      ]

      async.series queue, (err, result) ->
        callback result


  inviteUser: (browser, role, email, isNew) ->

    index = if role is 'member' then 2 else 1
    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    successMessage = ''

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    email = @fillInviteInputByIndex browser, index, email

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    if role is 'admin'
      browser
        .waitForElementVisible '.ContentModal', 50000
        .assert.containsText '.ContentModal.content-modal header', "You're adding an admin"
        .waitForElementVisible proceedButton, 20000
        .click proceedButton
      successMessage = "Invitation is sent to #{email}"

    unless isNew
      browser
        .waitForElementVisible '.ContentModal', 20000
        .assert.containsText '.ContentModal.content-modal header', 'Resend Invitation'
        .waitForElementVisible proceedButton, 20000
        .click proceedButton
      successMessage = "Invitation is resent to #{email}"

    @assertConfirmation browser, successMessage

  inviteAll: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    newEmailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(4) .kdinput.text.user-email"
    newUserEmail = "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    successMessage = 'All invitations are sent.'

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    firstUserEmail = @fillInviteInputByIndex browser, 1
    secondUserEmail = @fillInviteInputByIndex browser, 2
    thirdUserEmail = @fillInviteInputByIndex browser, 3

    browser
      .pause 3000
      .waitForElementVisible newEmailInputSelector, 10000
      .setValue newEmailInputSelector, newUserEmail
      .pause 5000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

  uploadCSV: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    uploadCSVButtonSelector = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.ft"
    message = 'Coming Soon!'

    browser
      .waitForElementVisible invitationsModalSelector, 20000
      .click uploadCSVButtonSelector
      .waitForElementVisible '.content-modal.csv-upload', 20000
      .assert.containsText '.ContentModal.csv-upload .kdmodal-title span.title', 'Upload CSV File'
      .click '.ContentModal.csv-upload .button-wrapper .kdbutton.cancel'


  newInviteFromResendModal: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    userEmail = @inviteUser browser, role
    index = if role is 'member' then 2 else 1
    browser
      .pause 5000
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    newEmail  = @fillInviteInputByIndex browser, index + 1
    successMessage = "Invitation is sent to #{newEmail}"

    browser
      .click sendInvitesButton
    if role is 'admin'
      @acceptConfirmModal browser
      successMessage = 'All invitations are sent'
    @rejectConfirmModal browser
    @assertConfirmation browser, successMessage


  rejectConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    cancelButton = '.kdmodal-content .kdbutton.solid.medium:nth-of-type(2)'
    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible cancelButton, 10000
            .click                 cancelButton


  acceptConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    confirmButton = '.kdmodal-content .kdbutton.confirm.solid.green.medium.w-loader'

    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible proceedButton, 10000
            .click                 proceedButton


  assertConfirmation: (browser, successMessage) ->

    browser
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', successMessage
      .pause 3000


  fillInviteInputByIndex: (browser, index, userEmail = null) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
    userEmail ?= "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"
    browser
      .waitForElementVisible emailInputSelector, 20000
      .setValue emailInputSelector, userEmail

    return userEmail

  clearInviteInputByIndex: (browser, index) ->
    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"

    browser
      .click invitationsModalSelector
      .waitForElementVisible emailInputSelector, 20000
      .clearValue emailInputSelector
      .setValue emailInputSelector, ''
      .click invitationsModalSelector


  inviteUsers: (browser, invitations, callback) ->

    fn = ( invitations, done ) ->
      _remote.api.JInvitation.create { invitations: invitations }, (err) ->
        done err

    browser
      .timeoutsAsyncScript 10000
      .executeAsync  fn, [ invitations ], (result) ->
        callback()


  acceptAndJoinInvitation: (host, browser, user, callback) ->

    fn = ( email, done ) ->
      _remote.api.JInvitation.some { 'email': email }, {}, (err, invitations) ->
        if invitations.length
          invitation = invitations[0]
          done invitation.code
        else
          done()

    browser
      .timeoutsAsyncScript 10000
      .executeAsync fn, [user.email], (result) =>

        { status, value } = result

        if status is 0 and value
          browser.waitForElementVisible '#main-sidebar .logo-wrapper .nickname', 50000, yes, =>
            @logoutTeam browser, =>
              teamUrl       = helpers.getUrl yes
              invitationUrl = "#{teamUrl}/Invitation/#{result.value}"
              browser.url invitationUrl, =>
                @fillJoinForm browser, user, yes, =>
                  browser.waitForElementVisible '#main-sidebar .logo-wrapper .nickname', 20000, yes, =>
                    @logoutTeam browser, (res) =>
                      @loginToTeam browser, host, no, '',  ->
                        callback res
        else
          callback('alreadyMember')

  checkTeammates: (browser, invitation, actionSelector1, actionSelector2, roleSelector, revoke = no, callback) ->

    unless invitation.accepted
      if revoke
        browser
          .pause 1000
          .click actionSelector2
          .pause 5000, -> callback()
      else
        browser
          .pause 1000
          .click actionSelector1
          .waitForElementVisible '.kdnotification.main', 20000
          .assert.containsText '.kdnotification.main', 'Invitation is resent.'
          .pause 1000, -> callback()
    else
      switch invitation.accepted
        when 'Member', 'Admin'
          browser
            .pause 1000
            .click actionSelector2
            .pause 1000
            .click roleSelector
            .pause 1000
            .click actionSelector2
            .pause 1000
            .waitForElementVisible roleSelector, 20000
            .assert.containsText roleSelector, invitation.accepted
            .pause 1000, -> callback()
        when 'Owner'
          browser
            .pause 1000
            .click 'body .ListView-row'
            .waitForElementVisible roleSelector, 20000
            .assert.containsText roleSelector, invitation.accepted
            .pause 1000, -> callback()
