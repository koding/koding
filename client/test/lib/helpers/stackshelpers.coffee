helpers              = require '../helpers/helpers.js'
teamsHelpers         = require '../helpers/teamshelpers.js'
utils                = require '../utils/utils.js'
stackEditorUrl       = "#{helpers.getUrl(yes)}/Home/stacks"
stackSelector        = null
sectionSelector      = '.kdview.kdtabpaneview.stacks'
newStackButton       = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
teamStacksSelector   = '.HomeAppView--section.team-stacks'
stackTemplate        = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"
draftStacksSelector  = '.HomeAppView--section.drafts'
menuSelector         = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
editSelector         = "#{menuSelector}:nth-of-type(1)"
stackEditorView      = '.StackEditorView'
sideBarSelector      = '#main-sidebar'
teamHeaderSelector   = '.SidebarTeamSection .SidebarStackSection.active h4'
draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft'
removeStackModal     = '[testpath=RemoveStackModal]'
removeButton         = '.kdbutton.solid.red.medium'
visibleStack         = '[testpath=StackEditor-isVisible]'
stackEditorHeader    = "#{visibleStack} .StackEditorView--header"
stackTemplateNameArea  = "#{stackEditorHeader} .kdinput.text.template-title.autogrow"
saveButtonSelector     = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
stackEditorTab         = "#{visibleStack} .kdview.kdtabview.StackEditorTabs"
credentialsTabSelector = 'div.kdtabhandle.credentials'
listCredential         = '.kdview.stacks.stacks-v2'
deletebutton           = "#{visibleStack} .custom-link-view.HomeAppView--button.danger"

WelcomeView            = '.WelcomeStacksView'
userstackLink          = "#{WelcomeView} ul.bullets li:nth-of-type(2)"
destroySelector        = "#{menuSelector}:nth-of-type(4)"
reinitSelector         = "#{menuSelector}:nth-of-type(2)"
notificationSelector   = '.kdnotification'

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
    # FIXME: reimplement after stacks page is done ~ HK
    # privateStacksSelector = '.HomeAppView--section.private-stacks'
    # stackTemplate = "#{privateStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    # browser
    #   .pause 2000
    #   .waitForElementVisible privateStacksSelector, 20000
    #   .waitForElementVisible stackTemplate, 20000

  seeDraftStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000, done


  editStackTemplates: (browser, done) ->
    @gotoStackTemplate browser, ->
      browser
        .waitForElementVisible stackTemplateNameArea, 2000
        .clearValue stackTemplateNameArea
        .pause 1000
        .setValue stackTemplateNameArea, 'NewStackName'
        .click saveButtonSelector, ->
          teamsHelpers.waitUntilToCreatePrivateStack browser, ->
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
      .waitForElementVisible listCredential, 20000, done

    browser.elements 'css selector', '.StackEditor-CredentialItem--info .custom-tag.inuse', (result) ->
      index = 0
      result.value.map (value) ->
        index += 1
        browser.elementIdText value.ELEMENT, (res) ->
          if res.value is 'IN USE'
            browser.assert.equal res.value, 'IN USE'
            browser.elementIdClick value.ELEMENT
            browser.pause 2000, ->
              browser.elements 'css selector', '.kdbutton.solid.compact.outline.red.secondary.delete', (buttons) ->
                buttonElement = buttons.value[index - 1].ELEMENT
                browser.elementIdClick buttonElement
                browser.pause 1000
                browser.waitForElementVisible '.kdnotification.main', 20000
                browser.assert.containsText '.kdnotification.main', 'This credential is currently in-use'


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
      .pause 1000, done


  deleteStackTemplates: (browser, done) ->
    @gotoStackTemplate browser, ->
    browser
      .waitForElementVisible deletebutton, 20000
      .click deletebutton
      .waitForElementVisible removeStackModal, 20000
      .click removeButton
      .pause 1000, done


  createPrivateStackAsMember: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, ->
      browser
        .pause 2000
        .waitForElementVisible WelcomeView, 20000
      teamsHelpers.createDefaultStackTemplate browser, (res) ->
        done

  checkAndDestroyVm: (browser, done) ->
    browser
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .click '.kdtabhandle.virtual-machines'
      .pause 2000
      .waitForElementVisible '.ListView-section.HomeAppViewVMSection', 20000
      .waitForElementVisible '.MachinesListItem-machineLabel', 20000
      #add disconnect vm


  destroy: (browser, done) ->
    browser
      .click sideBarSelector
      .waitForElementVisible teamHeaderSelector, 20000
      .click teamHeaderSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click destroySelector
      .waitForElementVisible '[testpath=deleteStack]', 20000
      .click removeButton


  gotoStackTemplate: (browser, callback) ->
    browser
      .pause 2000
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
    buildStackButton = ".kdbutton.turn-on.state-button.solid.green.medium.with-icon"

    browser
      .click '.HomeAppView .close-icon.closeModal'
      .click '.SidebarMachinesListItem--MainLink .SidebarListItem-title'
      .waitForElementVisible '.kdview.kdscrollview', 20000
    helpers.createFile(browser, host, null, null, 'Test.txt')
    browser
      .click sideBarSelector
      .waitForElementVisible teamHeaderSelector, 20000
      .click teamHeaderSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click reinitSelector
      .waitForElementVisible '[testpath=reinitStack]', 20000
      .pause 3000
      .click removeButton
      .waitForElementVisible notificationSelector, 20000
      .assert.containsText   notificationSelector, 'Reinitializing stack...'
      .pause 2000
      .waitForElementVisible buildStackButton, 20000
      .waitForElementNotPresent "span[title='config/Test.txt']", 50000
      .click buildStackButton, =>
        teamsHelpers.waitUntilVmRunning browser, done
