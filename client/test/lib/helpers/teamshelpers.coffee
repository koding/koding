helpers                  = require '../helpers/helpers.js'
utils                    = require '../utils/utils.js'
staticContents           = require '../helpers/staticContents.js'
path                     = require 'path'
awsKeyPath               = path.resolve __dirname, '../../../../../config/aws/worker_ci_test_key.json'
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
async                    = require 'async'


module.exports =


  enterTeamURL: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  '.TeamsModal--domain', 20000
      .waitForElementVisible  'input[name=slug]', 20000
      .click                  'button[testpath=domain-button]'
      .pause                  2000 # wait for modal change


  fillUsernamePasswordForm: (browser, user, invalidUserName = no) ->

    doneButton         = "#{teamsModalSelector} button.TeamsModal-button--green"
    usernameInput      = "#{teamsModalSelector} input[name=username]"
    passwordInput      = "#{teamsModalSelector} input[name=password]"
    alreadyMemberModal = "#{teamsModalSelector}.alreadyMember"
    usernameErrorMsg   = '.validation-error .kdview.wrapper'

    browser
      .waitForElementVisible   teamsModalSelector, 20000

    if invalidUserName
      browser
        .waitForElementVisible  usernameInput, 20000
        .clearValue             usernameInput
        .setValue               usernameInput, 'abc'
        .setValue               passwordInput, user.password
        .click                  doneButton
        .waitForElementVisible  usernameErrorMsg, 20000
        .assert.containsText    usernameErrorMsg, 'Username should be between 4 and 25 characters!'
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


  loginToTeam: (browser, user, invalidCredentials = no, callback = -> ) ->

    incorrectEmailAddress = 'a@b.com'
    incorrectUserName     = 'testUserName'
    wrongPassword         = 'password'
    unrecognizedMessage   = 'Unrecognized email'
    unknownUserMessage    = 'Unknown user name'
    wrongPasswordMessage  = 'Access denied'
    inputUserName         = 'input[name=username]'
    inputPassword         = 'input[name=password]'
    loginButton           = 'button[testpath=login-button]'


    browser
      .pause                  2000 # wait for login page
      .waitForElementVisible  '.TeamsModal--login', 20000
      .waitForElementVisible  'form.login-form', 20000
      .setValue               'input[name=username]', user.username
      .setValue               'input[name=password]', user.password
      .click                  'button[testpath=login-button]', => @loginAssertion browser, callback



  loginTeam: (browser, invalidCredentials = no, callback = -> ) ->

    user               = utils.getUser()
    url                = helpers.getUrl(yes)
    inviteLink         = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"
    invalidCredentials = no

    teamsLogin        = '.TeamsModal--login'
    stackCatalogModal = '.StackCatalogModal'
    stackCloseButton  = "#{stackCatalogModal} .kdmodal-inner .closeModal"

    browser.url url
    browser.maximizeWindow()

    browser.pause  3000
    browser.element 'css selector', teamsLogin, (result) =>
      if result.status is 0
        @loginToTeam browser, user, invalidCredentials
      else
        @createTeam browser, user, inviteLink

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

    modalSelector   = '.kdview.kdtabpaneview.username'
    sectionSelector = "#{modalSelector} section"
    browser
      .waitForElementVisible modalSelector, 20000
      .click                 '.TeamsModal-button-link a'
      .pause                 2000
      .waitForElementVisible modalSelector, 20000
      .pause                 2000
      .click                 '.TeamsModal-button-link a'
      .pause                 2000


  createTeam: (browser, user, inviteOrCreateLink, invalidCredentials = no, callback) ->

    modalSelector       = '.TeamsModal.TeamsModal--create'
    emailSelector       = "#{modalSelector} input[name=email]"
    companyNameSelector = "#{modalSelector} input[name=companyName]"
    signUpButton        = "#{modalSelector} button[type=submit]"
    user                = utils.getUser()
    inviteLink          = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"
    modalSelector       = '.TeamsModal.TeamsModal--create'
    teamsModalSelector  = '.TeamsModal--groupCreation'
    doneButton          = "#{teamsModalSelector} button.TeamsModal-button--green"
    usernameInput       = "#{teamsModalSelector} input[name=username]"
    passwordInput       = "#{teamsModalSelector} input[name=password]"
    errorMessage        = '.kdnotification.main'

    browser
      .url                    inviteOrCreateLink
      .waitForElementVisible  modalSelector, 20000
      .waitForElementVisible  emailSelector, 20000
      .waitForElementVisible  companyNameSelector, 20000
      .clearValue             emailSelector

    if inviteOrCreateLink is inviteLink
      browser
        .setValue              emailSelector, user.email
        .pause                 2000
        .setValue              companyNameSelector, user.teamSlug
        .click                 signUpButton
        .pause                 2500

      @enterTeamURL(browser)
      @checkForgotPassword(browser)

      if invalidCredentials
        @fillUsernamePasswordForm(browser, user, yes)
      else
        @fillUsernamePasswordForm(browser, user)

    else
      browser
        .setValue              emailSelector, user.email + 'test'
        .pause                 2000
        .setValue              companyNameSelector, user.teamSlug + 'test'
        .click                 signUpButton
        .pause                 2500

      @enterTeamURL(browser)

      browser
        .waitForElementVisible  teamsModalSelector, 20000
        .waitForElementVisible  usernameInput, 20000
        .clearValue             usernameInput
        .setValue               usernameInput, user.username
        .setValue               passwordInput, user.password
        .click                  doneButton
        .waitForElementVisible  errorMessage, 20000
        .assert.containsText    errorMessage, "Sorry, #{user.username} is already taken!"



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
    stackOnboardingPage = '.kdview.stack-onboarding.main-content.get-started'
    createStackButton = '.kdbutton.GenericButton.StackEditor-OnboardingModal--create'
    providers = '.providers.box-wrapper'
    providerSelector = "#{providers} .provider.box.#{provider}"
    skipGuideButton = '.kdview.stack-onboarding.main-content a.custom-link-view.HomeAppView--button'
    stackEditorTab = '.kdview.kdtabview.StackEditorTabs'
    credentialsTabSelector = "#{stackEditorTab} div.kdtabhandle.credentials.notification"
    checkForCredentials = ".kdview.kdlistitemview.kdlistitemview-default.StackEditor-CredentialItem.#{provider}"
    createNewButton = '.kdview.stacks.step-creds .kdbutton.add-big-btn.with-icon'


    browser
      .url "#{url}/Home/stacks"
      .waitForElementVisible stacksPageSelector, 20000
      .click newStackButton
      .pause 1000
      .waitForElementVisible stackOnboardingPage, 20000
      .waitForElementVisible createStackButton, 20000
      .click createStackButton
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
    eu_west_1 = "#{regionSelector} option[value=eu-west-1]"

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
    sidebarStackSection = "#{sidebarSelector} .SidebarSection-body"
    buildStackModal = '.kdmodal.env-modal.env-machine-state.kddraggable.has-readme'
    buildStackButton = "#{buildStackModal} .kdbutton.turn-on.state-button.solid.green.medium.with-icon"
    progressBarSelector = "#{buildStackModal} .progressbar-container"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"

    browser
      .click '#main-sidebar'
      .waitForElementVisible sidebarSelector, 20000
      .click sidebarStackSection

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is -1
        @createCredential browser, 'aws', 'build-stack', no, (res) =>
          @createStack browser, ->

    browser.getAttribute vmSelector, 'title', (result) =>
      ###
        Machine status: 'status'
        substring function remove 'Machine status:'
        from title attribute
      ###
      status = result.value.substring 16

      switch status
        when 'NotInitialized' then @turnOnVm browser, yes, done
        when 'Running' then done()
        when 'Stopping' then @waitUntilVmStopping browser, done
        when 'Stopped' then @turnOnVm browser, no, done
        when 'Starting' then @waitUntilVmRunning browser, done


  turnOnVm: (browser, firstBuild = no, done = -> ) ->

    sidebarSelector = '.SidebarTeamSection'
    sidebarStackSection = "#{sidebarSelector} .SidebarSection-body"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"
    buildStackModal = '.kdmodal.env-modal.env-machine-state.kddraggable.has-readme'
    buildStackButton = "#{buildStackModal} .kdbutton.turn-on.state-button.solid.green.medium.with-icon"

    unless firstBuild
      buildStackModal = '.kdmodal.env-modal.env-machine-state'
      buildStackButton = "#{buildStackModal} .kdbutton.turn-on.state-button.solid.green.medium.with-icon"

    browser
      .waitForElementVisible buildStackModal, 20000
      .waitForElementVisible buildStackButton, 20000
      .click buildStackButton, =>
        @waitUntilVmRunning browser, done


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
      .pause 10000
      .getAttribute vmSelector, 'title', (result) =>
        if result.value.substring(16) is 'Running'
          console.log '   VM is running'
          done()
        else
          console.log '   VM is still building'
          @waitUntilVmRunning browser, done


  createStack: (browser, done) ->


    sidebarSelector = '.SidebarTeamSection'
    sidebarStackSection = "#{sidebarSelector} .SidebarSection-body"
    vmSelector = "#{sidebarStackSection} .SidebarMachinesListItem cite"

    credentialSelector = '.kdview.kdlistitemview.kdlistitemview-default.StackEditor-CredentialItem'
    useThisAndContinueButton = '.StackEditor-CredentialItem--buttons .kdbutton.solid.compact.outline.verify'
    editorPaneSelector = '.kdview.pane.editor-pane.editor-view'
    saveButtonSelector = '.StackEditorView--header .kdbutton.GenericButton.save-test'
    successModal = '.kdmodal-inner .kdmodal-content'
    closeButton = '.kdmodal-inner .kdview.kdmodal-buttons .kdbutton.solid.medium.gray'

    browser
      .element 'css selector', vmSelector, (result) ->
        if result.status is 0
          done()
        else
          browser
            .pause 1000
            .click useThisAndContinueButton
            .waitForElementVisible editorPaneSelector, 20000
            .click saveButtonSelector
            .pause 10000 # here wait around 50 secs to create stack
            .waitForElementVisible successModal, 40000
            .click closeButton
            .pause 2000, ->
              done()


  createDefaultStackTemplate: (browser, done) ->

    stackEditorUrl = "#{helpers.getUrl(yes)}/Home/stacks"

    @createCredential browser, 'aws', 'draft-stack', yes, (res) =>
      @createPrivateStack browser, 'PrivateStack', (res) ->
        browser.url stackEditorUrl, ->
          done res.value


  createPrivateStack: (browser, stackName, done) ->

    stackEditorHeader = '.StackEditorView--header'
    useThisAndContinueButton = '.StackEditor-CredentialItem--buttons .kdbutton.solid.compact.outline.verify'
    editorPaneSelector = '.kdview.pane.editor-pane.editor-view'
    stackTemplateNameArea = "#{stackEditorHeader} .kdinput.text.template-title.autogrow"
    saveButtonSelector = '.StackEditorView--header .kdbutton.GenericButton.save-test'

    browser
      .pause 2000
      .click useThisAndContinueButton
      .waitForElementVisible editorPaneSelector, 20000
      .waitForElementVisible stackTemplateNameArea, 2000
      .setValue stackTemplateNameArea, ''
      .pause 1000
      .setValue stackTemplateNameArea, stackName
      .click saveButtonSelector, =>
        @waitUntilToCreatePrivateStack browser, done


  defineCustomVariables: (browser) ->

    wrongCustomVariable    = "foo: '"
    correctCustomVariable  = "foo: 'bar'"
    errorIndicator         = '.kdtabhandle.custom-variables .indicator.red.in'

    @switchTabOnStackCatalog browser, 'variables'
    @setTextToEditor browser, 'variables', wrongCustomVariable
    browser
      .waitForElementVisible errorIndicator, 20000
      .pause 1000

    @setTextToEditor browser, 'variables', correctCustomVariable
    browser
      .waitForElementNotVisible errorIndicator, 20000
      .pause 1000

    @switchTabOnStackCatalog browser, 'template'
    @setTextToEditor browser, 'template', staticContents.stackTemplate


  getAwsKey: -> return awsKey


  # possible values of tabName variable is 'stack', 'variables' or 'readme'
  switchTabOnStackCatalog: (browser, tabName) ->

    selector    =
      template  : '.stack-template'
      variables : '.custom-variables'
      readme    : '.readme'

    tabSelector = "#{stackCatalogModal} .kdtabhandle#{selector[tabName]}"

    browser
      .waitForElementVisible stackCatalogModal, 20000
      .waitForElementVisible tabSelector, 20000
      .click                 tabSelector


  # possible values of tabName variable is 'template', 'variables' or 'readme'
  setTextToEditor: (browser, tabName, text) ->

    viewNames   =
      template  : 'stackTemplateView'
      variables : 'variablesView'
      readme    : 'readmeView'

    viewName = viewNames[tabName]
    params   = [ viewName, text ]

    fn = (viewName, text) ->
      _kd.singletons.appManager.appControllers.Stacks.instances.first
        .mainView.tabs.activePane.mainView.defineStackView[viewName]
        .editorView.setContent text

    browser.execute fn, params


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



  logoutTeam: (browser, callback) ->

    browser
      .click '#main-sidebar'
      .waitForElementVisible '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 20000
      .click '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistview-contextmenu.default', 20000
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default', 2000
      .click '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default:nth-of-type(4)'

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


  inviteUser: (browser, role) ->

    index = if role is 'member' then 2 else 1

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail

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
    @assertConfirmation browser, message


  resendInvitation: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    index = if role is 'member' then 2 else 1

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .pause 2000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    @acceptConfirmModal browser if role is 'admin'
    @assertConfirmation browser, successMessage
    browser
      .pause 10000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    successMessage = "Invitation is resent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser

    if role is 'admin'
      browser
        .pause 2000
      @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail


  newInviteFromResendModal: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    userEmail = @inviteUser browser, role
    index = if role is 'member' then 2 else 1
    browser
      .pause 5000
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    newEmail = @fillInviteInputByIndex browser, index + 1
    successMessage = "Invitation is sent to #{newEmail}"

    browser
      .click sendInvitesButton
    @acceptConfirmModal browser  if role is 'admin'
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
            .waitForElementVisible confirmButton, 10000
            .click                 confirmButton


  assertConfirmation: (browser, successMessage) ->

    browser
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', successMessage
      .pause 2000


  fillInviteInputByIndex: (browser, index, userEmail = null) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
    userEmail ?= "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"

    browser
      .waitForElementVisible emailInputSelector, 20000
      .setValue emailInputSelector, userEmail

    return userEmail


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
          browser.waitForElementVisible '.HomeAppView', 20000, yes, =>
            @logoutTeam browser, =>
              teamUrl       = helpers.getUrl yes
              invitationUrl = "#{teamUrl}/Invitation/#{result.value}"
              browser.url invitationUrl, =>
                @fillJoinForm browser, user, yes, =>
                  browser.waitForElementVisible '.HomeAppView', 20000, yes, =>
                    @logoutTeam browser, (res) =>
                      @loginToTeam browser, host, no, ->
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


  gotoSettingsMenu: (browser, menuItemSelector) ->
    menuSelector      = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
    teamnameSelector  = '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'

    browser
      .waitForElementVisible sidebarSelector, 20000
      .click sidebarSelector
      .waitForElementVisible teamnameSelector, 20000
      .click teamnameSelector
      .waitForElementVisible menuSelector, 2000
      .pause 3000
      .click menuItemSelector
      .pause 3000
