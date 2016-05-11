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
      .pause 2000
      .waitForElementVisible stackOnboardingPage, 20000
      .waitForElementVisible createStackButton, 20000
      .click createStackButton
      .waitForElementVisible providers, 20000
      .click providerSelector
      .waitForElementVisible skipGuideButton, 20000
      .click skipGuideButton
      .pause 5000
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
            .pause 2000, =>
              @fillCredentialsPage browser, credentialName, done
        else
          done()


  fillCredentialsPage: (browser, name, done) ->

    newCredentialPage = '.kdview.stacks.stacks-v2'
    saveButton = "#{newCredentialPage} button[type=submit]"

    { accessKeyId, secretAccessKey } = @getAwsKey()

    browser
      .waitForElementVisible newCredentialPage, 20000
      .scrollToElement saveButton
      .setValue "#{newCredentialPage} .title input", name
      .pause 1000
      .setValue "#{newCredentialPage} .access-key input", accessKeyId
      .pause 1000
      .setValue "#{newCredentialPage} .secret-key input", secretAccessKey
      .pause 1000
      .click saveButton, -> done()


  createStack: (browser, done) ->

    url = helpers.getUrl(yes)

    credentialSelector = '.kdview.kdlistitemview.kdlistitemview-default.StackEditor-CredentialItem'
    useThisAndContinueButton = '.StackEditor-CredentialItem--buttons .kdbutton.solid.compact.outline.verify'
    editorPaneSelector = '.kdview.pane.editor-pane.editor-view'
    saveButtonSelector = '.StackEditorView--header .kdbutton.GenericButton.save-test'
    successModal = '.kdmodal-inner .kdmodal-content'
    closeButton = '.kdmodal-inner .kdview.kdmodal-buttons .kdbutton.solid.medium.gray'
    browser
      .pause 2000
      .click useThisAndContinueButton
      .waitForElementVisible editorPaneSelector, 20000
      .click saveButtonSelector
    browser.element 'css selector', successModal, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible successModal, 40000
          .click closeButton, ->
            browser.end()
            done()
      else
        browser.end()
        done()



  clickSaveAndTestButton: (browser) ->

    saveAndTestButton    = '.template-title-form .buttons .save-test'
    editorSelector       = '.stack-template .output .output-view'
    loaderIconNotVisible = "#{saveAndTestButton} .kdloader.hidden"

    browser
      .waitForElementVisible     saveAndTestButton, 20000
      .scrollToElement           saveAndTestButton
      .click                     saveAndTestButton
      .waitForElementVisible     editorSelector, 35000
      .waitForElementVisible     '.template-title-form .buttons .save-test .kdloader', 20000
      .waitForElementNotVisible  loaderIconNotVisible, 500000
      .pause                     3000


  saveTemplate: (browser, deleteStack = yes, checkTags = yes, doExtra = yes) ->

    stackModal           = '.stack-modal'
    modalCloseButton     = "#{stackModal} .gray"
    stackTabSelector     = '.team-stack-templates .kdtabhandle.stack-template.active'
    finalizeStepsButton  = "#{sidebarSelector} a[href='/Home/Welcome']:not(.SidebarSection-headerTitle)"

    if doExtra
      @seeTemplatePreview(browser)
      @updateStackReadme(browser)
      @defineCustomVariables(browser)

    @clickSaveAndTestButton(browser)

    browser.element 'css selector', stackModal, (result) ->
      if result.status is 0
        browser
          .assert.containsText    stackModal, 'Your stack script has been successfully saved'
          .waitForElementVisible  modalCloseButton, 20000
          .click                  modalCloseButton

    browser
      .waitForElementVisible     stackTabSelector, 20000
      .waitForElementVisible     stackModalCloseButton, 20000
      .click                     stackModalCloseButton
      .pause                     3000
      .waitForElementVisible     sidebarStackSection, 20000
      .waitForElementNotPresent  finalizeStepsButton, 20000
      .waitForElementVisible     envMachineStateModal, 20000

    if checkTags
      @checkStackTemplateTags(browser, deleteStack)


  checkStackTemplateTags: (browser, deleteStack) ->

    inUseTag       = "#{stackCatalogModal} [testpath=StackInUseTag]"
    defaultTag     = "#{stackCatalogModal} [testpath=StackDefaultTag]"
    accessTag      = "#{stackCatalogModal} [testpath=StackAccessLevelTag]"
    deleteMenuItem = '.kdbuttonmenu .context-list-wrapper .delete'

    @openStackCatalog(browser, no)

    browser
      .waitForElementVisible  stackTemplateList, 20000
      .waitForElementVisible  inUseTag, 20000
      .waitForElementVisible  defaultTag, 20000
      .waitForElementVisible  accessTag, 20000
      .assert.containsText    accessTag, 'GROUP'

    if deleteStack
      browser
        .waitForElementVisible    stackSettingsMenuIcon, 20000
        .click                    stackSettingsMenuIcon
        .pause                    2000
        .waitForElementVisible    deleteMenuItem, 20000
        .click                    deleteMenuItem
        .assert.containsText      '.kdnotification.main', 'This template currently in use by the Team'
        .waitForElementNotVisible '.kdnotification.main', 30000

    browser
      .waitForElementVisible  stackModalCloseButton, 20000
      .click                  stackModalCloseButton


  editStack: (browser, openEditorAndClone = no) ->

    editMenuItem             = '.kdbuttonmenu .context-list-wrapper .edit'
    openEditorButton         = '.kdmodal-inner .kdmodal-buttons .red'
    openEditorAndCloneButton = '.kdmodal-inner .kdmodal-buttons .green'
    stackTemplatePage        = '.define-stack-view .stack-template'
    stackEditorSelector      = "#{stackTemplatePage} .editor-pane"
    numberNotification       = "#{sidebarStackSection} .SidebarListItem-unreadCount"
    myStacksPage             = '.environments-modal.My-Stacks'
    stackItems               = "#{myStacksPage} .environment-item"
    makeTeamDefaultButton    = '.stacks .template-title-form .set-default'
    makeTeamDefaultLoader    = "#{makeTeamDefaultButton} .kdloader.hidden"
    newStackTemplate         = '.stacktemplates .stack-template-list .stacktemplate-item:last-child .title'
    newStackInSidebar        = '.SidebarStackSection .SidebarMachinesListItem .SidebarMachinesListItem--MainLink'
    updateNotification       = "#{stackItems} .update-notification"
    updateStackButton        = "#{updateNotification} .reinit-stack"
    reinitModal              = '.kdmodal[testpath=reinitStack]'
    proceedButton            = "#{reinitModal} .red"
    sidebarStackWidget       = '.SidebarStackWidgets'


    browser.pause  3000
    @openStackCatalog(browser, no)

    browser
      .waitForElementVisible  stackTemplateList, 20000
      .waitForElementVisible  stackSettingsMenuIcon, 20000
      .click                  stackSettingsMenuIcon
      .pause                  2000
      .waitForElementVisible  editMenuItem, 20000
      .click                  editMenuItem
      .pause                  2000

    if openEditorAndClone
      browser
        .waitForElementVisible  openEditorAndCloneButton, 20000
        .click                  openEditorAndCloneButton
    else
      browser
        .waitForElementVisible  openEditorButton, 20000
        .click                  openEditorButton

    browser
      .waitForElementVisible  stackTemplatePage, 20000
      .waitForElementVisible  stackEditorSelector, 20000

    @setTextToEditor browser, 'template', staticContents.multiMachineStackTemplate

    if openEditorAndClone
      @createCredential(browser, no, no, yes)

    @clickSaveAndTestButton(browser)

    if openEditorAndClone
      browser
        .waitForElementVisible  makeTeamDefaultButton, 20000
        .click                  makeTeamDefaultButton
        .pause                  3000
        .waitForElementVisible  '.stacktemplates', 20000

    browser
      .waitForElementVisible  stackModalCloseButton, 20000
      .click                  stackModalCloseButton

    if openEditorAndClone
      browser
        .waitForElementVisible  sidebarStackWidget, 20000
        .waitForTextToContain   sidebarStackWidget, 'Team admin has changed the default stack'
        .click                  "#{sidebarStackWidget} a"
        .waitForElementVisible  stackItems, 20000
        .click                  "#{stackItems} .red"

    else
      browser
        .waitForElementVisible  newStackInSidebar, 20000
        .waitForElementVisible  numberNotification, 20000
        .click                  numberNotification
        .waitForElementVisible  stackItems, 20000
        .waitForElementVisible  updateNotification, 20000
        .assert.containsText    updateNotification, 'has updated this stack'
        .waitForElementVisible  updateStackButton, 20000
        .click                  updateStackButton

    browser
      .waitForElementVisible  reinitModal, 20000
      .click                  proceedButton
      .waitForTextToContain   sidebarSelector, 'mexample'


  deleteStack: (browser) ->

    deleteMenuItem = '.kdbuttonmenu .context-list-wrapper .delete'
    stackTemplate  = '.stacktemplates .stack-template-list [testpath=privateStackListItem]'
    stackMenuIcon  = "#{stackTemplate} .stack-settings-menu"
    deleteModal    = '.kdmodal[testpath=RemoveStackModal]'
    deleteButton   = "#{deleteModal} .red"


    browser.element 'css selector', stackCatalogModal, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible  stackCatalogModal, 20000
          .waitForElementVisible  closeButton, 20000
          .click                  closeButton

    @openStackCatalog(browser)

    browser
      .waitForElementVisible    myStackTemplatesButton, 20000
      .click                    myStackTemplatesButton
      .waitForElementVisible    stackTemplate, 20000
      .pause                    3000
      .waitForElementVisible    stackMenuIcon, 20000
      .click                    stackMenuIcon
      .waitForElementVisible    deleteMenuItem, 20000
      .click                    deleteMenuItem
      .pause                    3000
      .waitForElementVisible    deleteModal, 20000
      .assert.containsText      "#{deleteModal} .kdmodal-title", 'Remove stack template ?'
      .waitForElementVisible    deleteButton, 20000
      .click                    deleteButton
      .waitForElementNotPresent deleteModal, 20000
      .waitForElementVisible    closeButton, 20000
      .click                    closeButton


  buildStack: (browser) ->

    buildStackButton     = "#{envMachineStateModal} .content-container .state-button"
    progressbarContainer = "#{envMachineStateModal} .progressbar-container"
    credentialsModal     = '.kdmodal[testpath=BuildRequirementsModal]'
    addedCredential      = "#{credentialsModal} .credential-item"
    titleInput           = "#{credentialsModal} input[name=title]"
    usernameInput        = "#{credentialsModal} input[name=username]"
    passwordInput        = "#{credentialsModal} input[name=password]"
    credentialSaveButton = "#{credentialsModal} button.green"
    useCredentialButton  = "#{addedCredential} .kdbutton:not(.secondary)"
    readmeMarkdown       = "#{envMachineStateModal} .content-readme"
    readmeHeader         = "#{readmeMarkdown} #test-stack-readme"
    readmeLink           = "#{readmeMarkdown} a"

    browser
      .waitForElementVisible     buildStackButton, 20000
      .waitForElementVisible     readmeMarkdown, 20000
      .waitForElementVisible     readmeHeader, 20000
      .waitForElementVisible     readmeLink, 20000
      .click                     buildStackButton
      .pause                     3500 # wait for credentials modal

    browser.element 'css selector', credentialsModal, (result) ->
      if result.status is 0

        browser.element 'css selector', addedCredential, (result) ->
          if result.status isnt 0
            browser
              .waitForElementVisible   titleInput, 20000
              .waitForElementVisible   usernameInput, 20000
              .waitForElementVisible   passwordInput, 20000
              .setValue                titleInput, 'Build requirement data for testing'
              .setValue                usernameInput, 'FOO'
              .setValue                passwordInput, 'BAR'
              .click                   credentialSaveButton
              .waitForElementVisible   addedCredential, 20000

          browser
            .waitForElementVisible     useCredentialButton, 20000
            .click                     useCredentialButton

      browser
        .waitForElementVisible     progressbarContainer, 20000
        .waitForElementNotPresent  progressbarContainer, 500000
        .pause                     3000 # wait for machine
        .waitForElementVisible     stackMachine, 20000

    browser.isStackBuilt = yes


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


  reinitStack: (browser) ->

    myStacksLink  = '.AppModal-navItem.my-stacks'
    stackItem     = '.kdlistitemview.environment-item'
    reinitButton  = "#{stackItem} .button-container .red"
    reinitModal   = '.kdmodal[testpath=reinitStack]'
    proceedButton = "#{reinitModal} .red"
    notification  = '.kdnotification.main'

    @openStackCatalog(browser, no)

    browser
      .waitForElementVisible    myStacksLink, 20000
      .click                    myStacksLink
      .waitForElementVisible    stackItem, 20000
      .click                    reinitButton
      .waitForElementVisible    reinitModal, 20000
      .click                    proceedButton
      .waitForElementNotPresent stackCatalogModal, 30000
      .waitForElementVisible    envMachineStateModal, 20000


  destroyEverything: (browser) ->

    if browser.isStackBuilt
      @reinitStack(browser)
      browser.pause 10000 # wait before credential destroy
      @createStack(browser, yes)
      @createCredential(browser, no, yes)


  seeTemplatePreview: (browser) ->

    templatePreviewButton     = '.stack-template .template-preview-button'
    stackTemplatePreviewModal = '.stack-template-preview'
    tabsSelector              = "#{stackTemplatePreviewModal} .kdmodal-content .kdtabhandle-tabs"
    yamlTabSelector           = "#{tabsSelector} .yaml"
    jsonTabSelector           = "#{tabsSelector} .json"
    stackTabSelector          = '.team-stack-templates .kdtabhandle.stack-template'

    browser
      .waitForElementVisible  stackTabSelector, 20000
      .click                  stackTabSelector
      .waitForElementVisible  templatePreviewButton, 20000
      .click                  templatePreviewButton
      .waitForElementVisible  stackTemplatePreviewModal, 20000
      .waitForElementVisible  yamlTabSelector, 20000
      .waitForElementVisible  jsonTabSelector, 20000
      .waitForElementVisible  stackModalCloseButton, 20000
      .click                  stackModalCloseButton


  updateStackReadme: (browser) ->

    @switchTabOnStackCatalog(browser, 'readme')
    @setTextToEditor(browser, 'readme', staticContents.readme)

    previewButton = '.editor-pane .preview-button'
    previewModal  = '[testpath=ReadmePreviewModal]'
    readmeLink    = 'https://koding.com/docs/creating-an-aws-stack'

    browser
      .waitForElementVisible  previewButton, 20000
      .click                  previewButton
      .waitForElementVisible  previewModal, 20000
      .assert.containsText    "#{previewModal} h3", 'Test stack readme'
      .waitForElementVisible  "#{previewModal} a[href='#{readmeLink}']", 20000
      .waitForElementVisible  stackModalCloseButton, 20000
      .click                  stackModalCloseButton


  getAwsKey: -> return awsKey


  checkIconsStacks: (browser, removeNewStack = yes) ->

    saveAndTestButton           = '.buttons button:nth-of-type(5)'
    stackTemplateSelector       = '.kdtabhandlecontainer.hide-close-icons .stack-template'
    stacksLogsSelector          = '.step-define-stack .kdscrollview'
    iconsSelector               = '.kdlistitemview-default.stacktemplate-item .stacktemplate-info'
    notReadyIconSelector        = "#{iconsSelector} .not-ready"
    privateIconSelector         = "#{iconsSelector} .private"
    stackTemplateSettingsButton = '.kdbutton.stack-settings-menu'
    deleteButton                = '.kdlistview-contextmenu.expanded .delete'
    confirmDeleteButton         = '.kdview.kdmodal-buttons .solid.red .button-title'

    browser
      .click                      saveAndTestButton
      .pause                      2000 #for stack creation logs to appear
      .waitForElementVisible      stacksLogsSelector, 20000
      .assert.containsText        stacksLogsSelector, 'An error occured: Required credentials are not provided yet'
      .click                      myStackTemplatesButton
      .waitForElementVisible      notReadyIconSelector, 30000
      .assert.containsText        notReadyIconSelector, 'NOT READY'
      .assert.containsText        privateIconSelector, 'PRIVATE'

    if removeNewStack
      browser
        .waitForElementVisible      stackTemplateSettingsButton, 20000
        .click                      stackTemplateSettingsButton
        .waitForElementVisible      deleteButton, 20000
        .click                      deleteButton
        .waitForElementVisible      confirmDeleteButton, 20000
        .click                      confirmDeleteButton
        .pause                      2000
        .waitForElementVisible      stackTemplateSelector, 20000
        .assert.containsText        stackTemplateSelector, 'Stack Template'
        .assert.containsText        saveAndTestButton, 'SAVE & TEST'

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


  enableAndDisableApiAccess: (browser, enableApi = no, disableApi = no) ->

    apiAccessSelector       = '.kdtabhandle-tabs .api-access.AppModal-navItem'
    toggleSwitch            = '.settings-row .koding-on-off.small.'
    toggledOffSwitch        = "#{toggleSwitch}off"
    toggledOnSwitch         = "#{toggleSwitch}on"
    addNewApiDisabledButton = '.kdtabhandlecontainer.hide-close-icons [disabled="disabled"]'
    addnewApiButton         = '.kdtabhandlecontainer.hide-close-icons .add-new'

    browser
      .waitForElementVisible     apiAccessSelector, 20000
      .click                     apiAccessSelector
      .element 'css selector', toggledOffSwitch, (result) ->
        if result.status is 0
          if enableApi
            browser
              .waitForElementVisible     toggledOffSwitch, 20000
              .pause                     2000
              .waitForElementVisible     addNewApiDisabledButton, 20000
              .click                     toggledOffSwitch
              .pause                     2000

          if disableApi
            browser
              .waitForElementVisible     toggledOnSwitch, 20000
              .waitForElementVisible     addnewApiButton, 20000
              .click                     toggledOnSwitch
              .pause                     2000
              .waitForElementVisible     addNewApiDisabledButton, 20000


  addNewApiToken: (browser) ->

    addnewApiButton = '.kdtabhandlecontainer.hide-close-icons .add-new'
    confirmDelete   = '.kddraggable.with-buttons .clearfix .solid.red'
    deleteButton    = '.kdlistitemview-member .role.subview .delete'
    tokenTimeStamp  = '.kdlistitemview-member .details .time'

    browser
      .click                     addnewApiButton
      .waitForElementVisible     deleteButton, 20000
      .assert.containsText       tokenTimeStamp, 'Created less than a minute ago by'
      .click                     deleteButton
      .waitForElementVisible     deleteButton, 20000
      .click                     confirmDelete
      .waitForElementNotVisible  tokenTimeStamp, 20000


  editStackName: (browser) ->

    stackTemplateSettingsButton = '.kdbutton.stack-settings-menu'
    saveAndTestButton           = '.buttons button:nth-of-type(5)'
    cancelButton                = '.buttons button:nth-of-type(2)'
    stacksLogsSelector          = '.step-define-stack .kdscrollview'
    myStackTemplatesButton      = '.kdview.kdtabhandle-tabs .my-stack-templates'
    templateInputSelector       = '.template-title-form .template-title .input-wrapper input'
    editedText                  = 'Edit stack name'
    stackNameSelector           = '.stacktemplate-info.clearfix .title'
    editButtonSelector          = '.kdbuttonmenu .context-list-wrapper .edit'

    browser
      .waitForElementVisible      stackTemplateSettingsButton, 20000
      .click                      stackTemplateSettingsButton
      .waitForElementVisible      editButtonSelector, 20000
      .click                      editButtonSelector
      .waitForElementVisible      templateInputSelector, 20000
      .clearValue                 templateInputSelector
      .setValue                   templateInputSelector, editedText
      .click                      saveAndTestButton
      .pause                      2000 #for stack creation logs to appear
      .waitForElementVisible      stacksLogsSelector, 20000
      .assert.containsText        stacksLogsSelector, 'An error occured: Required credentials are not provided yet'
      .click                      myStackTemplatesButton
      .waitForElementVisible      templateInputSelector, 20000
      .click                      cancelButton
      .waitForElementVisible      stackNameSelector, 20000
      .assert.containsText        stackNameSelector, editedText


  closeTeamSettingsModal: (browser) ->

    adminModal  = '.AppModal.AppModal--admin.team-settings'
    closeButton = "#{adminModal} .closeModal"

    browser
      .waitForElementVisible adminModal, 20000
      .click                 closeButton


  logoutTeam: (browser, callback) ->

    browser
      .click '#main-sidebar'
      .waitForElementVisible '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 20000
      .click '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistview-contextmenu.default', 20000
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default',2000
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
