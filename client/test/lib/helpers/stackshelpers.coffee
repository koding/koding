helpers                = require '../helpers/helpers.js'
teamsHelpers           = require '../helpers/teamshelpers.js'
utils                  = require '../utils/utils.js'
async                  = require 'async'
staticContents         = require '../helpers/staticContents.js'
stackEditorUrl         = "#{helpers.getUrl(yes)}/Home/stacks"
stackSelector          = null
sectionSelector        = '.kdview.kdtabpaneview.stacks'
newStackButton         = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
teamStacksSelector     = '.HomeAppView--section.team-stacks'
stackTemplate          = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"
draftStacksSelector    = '.HomeAppView--section.drafts'
privateStacksHeader    = '.HomeAppView--section.private-stacks'
menuSelector           = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
editSelector           = "#{menuSelector}:nth-of-type(1)"
stackEditorView        = '.StackEditorView'
sideBarSelector        = '#main-sidebar'
teamHeaderSelector     = '.SidebarTeamSection .SidebarStackSection.active h4'
draftStackHeader       = '.SidebarTeamSection .SidebarSection.draft'
removeStackModal       = '[testpath=RemoveStackModal]'
removeButton           = '.kdbutton.solid.red.medium'
visibleStack           = '[testpath=StackEditor-isVisible]'
stackEditorHeader      = "#{visibleStack} .StackEditorView--header"
stackTemplateNameArea  = "#{stackEditorHeader} .kdinput.text.template-title.autogrow"
saveButtonSelector     = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
stackEditorTab         = "#{visibleStack} .kdview.kdtabview.StackEditorTabs"
credentialsTabSelector = 'div.kdtabhandle.credentials'
listCredential         = '.kdview.stacks.stacks-v2'
deletebutton           = "#{visibleStack} .custom-link-view.HomeAppView--button.danger"
editNamebutton         = "#{visibleStack} .StackEditorView--header .edit-name"
WelcomeView            = '.WelcomeStacksView'
userstackLink          = "#{WelcomeView} ul.bullets li:nth-of-type(2)"
destroySelector        = "#{menuSelector}:nth-of-type(4)"
reinitSelector         = "#{menuSelector}:nth-of-type(2)"
notificationSelector   = '.kdnotification'
stacksSelector         = '.SidebarSection-headerTitle'
stackTitleSelector     = '.ListView > .ListView-section.HomeAppViewStackSection'
buildStackButton       = '.kdbutton.turn-on.state-button.solid.green.medium.with-icon'
closeModal             = '.HomeAppView .close-icon.closeModal'
sidebarVmSelector      = '.SidebarMachinesListItem--MainLink .SidebarListItem-title'
proceedButton          = '[testpath=proceed]'
draftStackTitle        = '.HomeAppView--section.drafts .ListView-section.HomeAppViewStackSection .HomeAppViewListItem.StackTemplateItem'
privateStacksTitle     = '.HomeAppView--section.private-stacks .ListView-section.HomeAppViewStackSection .HomeAppViewListItem.StackTemplateItem'
shareButton            = '[testpath=proceed]'
makeTeamDefaultButton  = '.StackEditorView--header .kdbutton.GenericButton.set-default'
reinitializeSelector   = '.SidebarStackWidgets .SidebarSection-body a'
reinitStackModal       = '[testpath=reinitStack]'
saveButtonSelector     = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
privateStacks          = '.SidebarTeamSection .SidebarSection:nth-of-type(2)  .HomeAppViewListItem-label'
privateStacksDraft     = '.HomeAppView--section.drafts .ListView-section.HomeAppViewStackSection .ListView-row:nth-of-type(2)'
addRemoveButton        = "#{privateStacksDraft} .HomeAppViewListItem .HomeAppViewListItem-SecondaryContainer .HomeAppView--button"
errorIndicator          = '.kdtabhandle.custom-variables .indicator.red.in'
customVariablesSelector = "#{stackEditorTab} div.kdtabhandle.custom-variables"
reinitNotification      = '.SidebarStackWidgets.--DifferentStackResources'

module.exports =

  clickNewStackButton: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible sectionSelector, 20000
      .click newStackButton
      .pause 2000
      .assert.urlContains '/Stack-Editor/New'
      .pause 1000, done

  seeTeamStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000, done

  seePrivateStackTemplates: (browser, done) ->
    browser
      .waitForElementVisible privateStacksHeader, 20000
      .waitForElementVisible privateStacksTitle, 20000, done

  seeDraftStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000, done


  editStackTemplates: (browser, done) ->
    browser.click closeModal
    @gotoStackTemplate browser, ->
      browser
        .waitForElementVisible stackTemplateNameArea, 2000
        .waitForElementVisible editNamebutton, 20000
        .click editNamebutton
        .clearValue stackTemplateNameArea
        .pause 3000
        .setValue stackTemplateNameArea, ''
        .setValue stackTemplateNameArea, 'NewStackName'
        .click saveButtonSelector, ->
          browser.pause 3000, ->
            browser
              .refresh()
              .waitForElementVisible stackEditorHeader, 20000
              .waitForElementVisible stackTemplateNameArea, 2000
              .getAttribute stackTemplateNameArea, 'placeholder', (result) ->
                this.assert.equal result.value, 'NewStackName'
                browser.pause 1000, done


  deleteCredentialInUse: (browser, done) ->
    browser
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000
      .click '.HomeAppViewListItem-label'
      .waitForElementVisible stackEditorHeader, 20000
      .click credentialsTabSelector
      .pause 2000
      .waitForElementVisible listCredential, 20000

    browser.elements 'css selector', '.StackEditor-CredentialItem--info .custom-tag.inuse', (result) ->
      index = 0
      result.value.map (value) ->
        browser.elementIdText value.ELEMENT, (res) ->
          if res.value is 'IN USE'
            browser.assert.equal res.value, 'IN USE'
            browser.elementIdClick value.ELEMENT
            browser.pause 2000, ->
              browser.elements 'css selector', '.StackEditor-CredentialItem--buttons .custom-link-view.delete', (buttons) ->
                buttonElement = buttons.value[index - 1].ELEMENT
                browser.elementIdClick buttonElement
                browser.pause 1000
                browser.waitForElementVisible '.kdnotification.main', 20000
                browser.assert.containsText '.kdnotification.main', 'This credential is currently in-use'
                browser.pause 1000, done

          index += 1


  deleteStackTemplatesInUse: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000
      .click '.HomeAppViewListItem-label'
      .waitForElementVisible stackEditorHeader, 20000
      .waitForElementVisible deletebutton, 20000
      .click deletebutton
      .waitForElementVisible notificationSelector, 20000
      .assert.containsText notificationSelector, 'This template currently in use by the Team.'
    browser.pause 1000, done


  deleteStackTemplates: (browser, done) ->
    @gotoStackTemplate browser, ->
    browser
      .waitForElementVisible deletebutton, 20000
      .click deletebutton
      .waitForElementVisible removeStackModal, 20000
      .click proceedButton
      .pause 1000, done


  destroy: (browser, done) ->
    browser.getText teamHeaderSelector, (res) ->
      browser
        .click closeModal
        .click sideBarSelector
        .waitForElementVisible teamHeaderSelector, 20000
        .click teamHeaderSelector
        .waitForElementVisible menuSelector, 20000
        .pause 1000
        .click destroySelector
        .waitForElementVisible '[testpath=deleteStack]', 20000
        .click proceedButton
        .pause 3000
        .waitForElementNotPresent '.SidebarMachinesListItem', 20000
        .click stacksSelector
        .waitForElementVisible teamStacksSelector, 20000
        .assert.containsText '.HomeAppView--section.team-stacks > ' + stackTitleSelector, "Your team doesn't have any stacks ready."
        .scrollToElement draftStacksSelector
        .waitForElementVisible draftStacksSelector, 20000
        .assert.containsText '.HomeAppViewListItem-label ', res.value
        .refresh()
        .pause 3000, done


  destroyPersonalStack: (browser, done) ->
    browser.refresh()
    browser.pause 1000, ->
      browser
        .url stackEditorUrl
        .waitForElementVisible sectionSelector, 20000
        .scrollToElement draftStacksSelector
        .waitForElementVisible privateStacksTitle, 20000
        .click privateStacksTitle + ' .HomeAppViewListItem-label'
        .pause 2000
        .getText teamHeaderSelector, (res) ->
          browser
            .click stacksSelector
            .waitForElementVisible teamStacksSelector, 20000
            .assert.containsText privateStacksTitle , res.value
            .click closeModal
            .click sideBarSelector
            .click teamHeaderSelector
            .waitForElementVisible menuSelector, 30000
            .pause 3000
            .click destroySelector
            .waitForElementVisible '[testpath=deleteStack]', 20000
            .click proceedButton
            .pause 3000
            .url stackEditorUrl
            .waitForElementVisible teamStacksSelector, 20000
            .scrollToElement draftStacksSelector
            .waitForElementVisible draftStacksSelector, 20000
            .assert.containsText privateStacksDraft , res.value
            .pause 1000, done


  gotoStackTemplate: (browser, callback) ->
    browser
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible draftStackHeader, 20000
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorHeader, 20000
      .pause 2000, -> callback()


  changeAndReinitializeStack: (browser, done) ->
    host = utils.getUser no, 0
    browser
      .click closeModal
      .click sidebarVmSelector
      .waitForElementVisible '.kdview.kdscrollview', 20000
    helpers.createFile(browser, host, null, null, 'Test.txt')
    browser
      .click sideBarSelector
      .waitForElementVisible teamHeaderSelector, 20000
      .click teamHeaderSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click reinitSelector
      .waitForElementVisible reinitStackModal, 20000
      .pause 2000
      .click proceedButton
      .waitForElementVisible notificationSelector, 20000
      .assert.containsText   notificationSelector, 'Reinitializing stack...'
      .pause 2000, ->
        browser
          .waitForElementNotPresent "span[title='config/Test.txt']", 50000
        teamsHelpers.turnOnVm browser, no, done


  addRemoveFromSideBar: (browser, done) ->
    browser
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .scrollToElement draftStacksSelector
      .waitForElementVisible addRemoveButton, 20000
      .click addRemoveButton
      .pause 5000
      .assert.containsText addRemoveButton, 'ADD TO SIDEBAR'
      .click addRemoveButton
      .assert.containsText addRemoveButton, 'REMOVE FROM SIDEBAR'
      .pause 1000, done


  defineCustomVariables: (browser, done) ->
    wrongCustomVariable    = "foo: '"
    correctCustomVariable  = "foo: 'bar'"

    @gotoStackTemplate browser, =>
      browser.waitForElementVisible stackTemplateNameArea, 2000
      @switchTabOnStackCatalog browser, 'variables'
      @setTextToEditor browser, 'variables', wrongCustomVariable
      browser
        .waitForElementVisible errorIndicator, 20000
        .pause 2000 , =>
          @setTextToEditor browser, 'variables', correctCustomVariable
          browser.pause 1000, =>
            browser.waitForElementNotPresent errorIndicator, 20000, =>
              @switchTabOnStackCatalog browser, 'template'
              @setTextToEditor browser, 'template', staticContents.stackTemplate
              browser.pause 1000, done


# possible values of tabName variable is 'stack', 'variables' or 'readme'
  switchTabOnStackCatalog: (browser, tabName) ->
    selector    =
      template  : '.stack-template'
      variables : '.custom-variables'
      readme    : '.readme'

    tabSelector = "#{stackEditorTab} div.kdtabhandle#{selector[tabName]}"
    browser
      .waitForElementVisible stackEditorTab, 20000
      .waitForElementVisible tabSelector, 20000
      .click                 tabSelector


  # possible values of tabName variable is 'template', 'variables' or 'readme'
  setTextToEditor: (browser, tabName, text) ->
    viewNames   =
      template  : 'StackTemplateView'
      variables : 'variablesView'
      readme    : 'ReadmeView'

    viewName = viewNames[tabName]
    params   = [ viewName, text ]

    if tabName is 'template'
      fn = (viewName, text) ->
        _kd.singletons.appManager.appControllers.Stackeditor.instances.first
        .selectedEditor.editorViews['stackTemplate'].editorView.setContent text
    else
      fn = (viewName, text) ->
        _kd.singletons.appManager.appControllers.Stackeditor.instances.first
        .selectedEditor.editorViews['variables'].editorView.setContent text
    browser.execute fn, params


  createAndMakeStackTeamDefault: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    admin       = utils.getUser no, 0

    queue = [
      (next) ->
        teamsHelpers.loginToTeam browser, targetUser1 , no, '', (result) ->
          browser
            .pause 2000
            .waitForElementVisible '.kdview', 20000
            .click sideBarSelector
            .waitForElementNotPresent reinitNotification, 20000
          next null, result
      (next) ->
        teamsHelpers.logoutTeamfromUrl browser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.loginToTeam browser, admin , no, '', (result) ->
          next null, result
      (next) ->
        teamsHelpers.createDefaultStackTemplate browser, (result) ->
          next null, result
      (next) =>
        @makeStackTeamDefault browser, (result) ->
          next null, result
      (next) =>
        @reinitializeTeamStack browser, (result) ->
          next null, result
    ]

    async.series queue, (err, result) ->
      done()  unless err


  makeStackTeamDefault: (browser, done) ->
    browser.elements 'css selector', makeTeamDefaultButton, (result) ->
      result.value.map (value) ->
        browser.elementIdText value.ELEMENT, (res) ->
          browser.elementIdDisplayed value.ELEMENT, (res) ->
            if res.value
              browser
                .elementIdClick value.ELEMENT, ->
                  teamsHelpers.waitUntilToCreateStack browser, ->
                    done()


  reinitializeTeamStack: (browser, done) ->
    browser
      .waitForElementVisible '.StackEditor-ShareModal.kdmodal footer', 20000
      .waitForElementVisible '.StackEditor-ShareModal.ContentModal.content-modal main p .kdcustomcheckbox', 20000
      .click '.StackEditor-ShareModal.ContentModal.content-modal main p .kdcustomcheckbox'
      .pause 2000
      .click shareButton
      .waitForElementVisible '.ContentModal.content-modal main', 20000
      .click shareButton, ->
        browser.waitForElementVisible reinitNotification, 20000
        browser.assert.containsText reinitializeSelector, 'Reinitialize Default Stack'
        browser
          .click sideBarSelector
          .click reinitializeSelector
          .waitForElementVisible reinitStackModal, 20000
          .pause 2000
          .click proceedButton
          .waitForElementVisible notificationSelector, 20000
          .assert.containsText   notificationSelector, 'Reinitializing stack...'
          .pause 2000, ->
            browser.waitForElementVisible '.kdview', 20000, done


  createPrivateStackAsMember: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, '', ->
      browser
        .pause 2000
        .waitForElementVisible '.kdview', 20000
        .click sideBarSelector
        .waitForElementVisible reinitNotification, 20000
        .assert.containsText reinitializeSelector, 'Reinitialize Default Stack'
        .url stackEditorUrl
      teamsHelpers.createPrivateStack browser, (res) ->
        teamsHelpers.createDefaultStackTemplate browser, (result) ->
          done()


  checkDraftsAsMember: (browser, done) ->
    admin          = utils.getUser no, 0
    adminUserName  = capitalize admin.username
    member         = utils.getUser no, 1
    memberUserName = capitalize member.username
    teamDefault    = adminUserName  + "'s StackDefaultStack"
    memberDraft    = memberUserName + "'s StackDefaultStack"
    privateStack   = adminUserName  + "'s StackPrivateStack"
    draftSelector  = '.HomeAppView--section.drafts .ListView-section.HomeAppViewStackSection .ListView-row'

    browser
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .scrollToElement draftStacksSelector
      .waitForElementVisible draftStacksSelector, 20000
      .assert.containsText "#{draftSelector}:nth-of-type(1) .HomeAppViewListItem-label" , teamDefault
      .assert.containsText "#{draftSelector}:last-child .HomeAppViewListItem-label" , memberDraft
      .expect.element("#{draftSelector}:last-child .HomeAppViewListItem-label").text.to.not.equal(privateStack)
    browser.pause 1000, done


  getStackTitle: (browser, selector, callback) ->
    browser.getText selector, (res) ->
      return res.value


capitalize = (word) ->
  newWord = word.charAt(0).toUpperCase() + word.slice 1
  return newWord
