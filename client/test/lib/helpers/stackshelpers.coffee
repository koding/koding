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
        index += 1
        browser.elementIdText value.ELEMENT, (res) ->
          if res.value is 'IN USE'
            browser.assert.equal res.value, 'IN USE'
            browser.elementIdClick value.ELEMENT
            browser.pause 2000, ->
              browser.elements 'css selector', '.kdbutton.solid.compact.outline.red.secondary.delete', (buttons) ->
                console.log(buttons)
                buttonElement = buttons.value[index - 2].ELEMENT
                browser.elementIdClick buttonElement
                browser.pause 1000
                browser.waitForElementVisible '.kdnotification.main', 20000
                browser.assert.containsText '.kdnotification.main', 'This credential is currently in-use'
                browser.pause 1000, done


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


  createPrivateStackAsMember: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    teamsHelpers.loginToTeam browser, targetUser1 , no, '', ->
      browser
        .pause 2000
        .waitForElementVisible '.kdview', 20000, ->
          teamsHelpers.createDefaultStackTemplate browser, (res) ->
            done

  # checkAndDestroyVm: (browser, done) ->
  #   browser
  #     .url stackEditorUrl
  #     .waitForElementVisible teamStacksSelector, 20000
  #     .click '.kdtabhandle.virtual-machines'
  #     .pause 2000
  #     .waitForElementVisible '.ListView-section.HomeAppViewVMSection', 20000
  #     .waitForElementVisible '.MachinesListItem-machineLabel', 20000
  #     #add disconnect vm


  destroy: (browser, done) ->
    browser.getText teamHeaderSelector, (res) ->
      browser
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
    saveButtonSelector = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
    browser.refresh()
    @gotoStackTemplate browser, ->
      browser
        .click saveButtonSelector
        .pause 10000 # here wait around 50 secs to verify stack
        .getText teamHeaderSelector, (res) ->
          browser
            .click sideBarSelector
            .waitForElementVisible draftStackHeader, 20000
            .click draftStackHeader
            .waitForElementVisible menuSelector, 20000
            .pause 1000
            .click reinitSelector #initiliaze stack
            .pause 3000
            .click stacksSelector
            .waitForElementVisible teamStacksSelector, 20000
            .assert.containsText privateStacksTitle , res.value 
            .click sideBarSelector
            .click teamHeaderSelector
            .waitForElementVisible menuSelector, 20000
            .pause 3000
            .click destroySelector
            .waitForElementVisible '[testpath=deleteStack]', 20000
            .click proceedButton
            .pause 3000
            .click stacksSelector
            .waitForElementVisible teamStacksSelector, 20000
            .scrollToElement draftStacksSelector
            .waitForElementVisible draftStacksSelector, 20000
            .assert.containsText draftStackTitle , res.value
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
      .waitForElementVisible '[testpath=reinitStack]', 20000
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
      .click '.HomeAppViewListItem-SecondaryContainer .HomeAppView--button'
      .assert.containsText '.HomeAppView--section .HomeAppView--button.primary', 'ADD TO SIDEBAR'
      .click '.HomeAppViewListItem-SecondaryContainer .HomeAppView--button'
      .assert.containsText '.HomeAppView--section .HomeAppView--button.primary', 'REMOVE FROM SIDEBAR'
      .pause 1000, done

  getStackTitle: (browser, selector, callback) ->
    browser.getText selector, (res) ->
      return res.value


