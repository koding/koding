teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
stackEditorUrl = "#{helpers.getUrl(yes)}/Home/stacks"
async = require 'async'
stackSelector = null


module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'test credential', no, (res) ->
          next null, res
      (next) ->
        teamsHelpers.createStack browser, (res) ->
          next null, res

      (next) ->
        teamsHelpers.createDefaultStackTemplate browser, (res) ->
          # remove main url from result
          # to get '/Stack-Editor/machineId'
          res = res.substring helpers.getUrl(yes).length
          stackSelector = res
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err

  stacks: (browser) ->

    sectionSelector = '.kdview.kdtabpaneview.stacks'
    newStackButton = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'

    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible sectionSelector, 20000
      .click newStackButton
      .pause 2000
      .assert.urlContains '/Stack-Editor/New'


    teamStacksSelector = '.HomeAppView--section.team-stacks'
    stackTemplate = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000

    # FIXME: reimplement after stacks page is done ~ HK
    # privateStacksSelector = '.HomeAppView--section.private-stacks'
    # stackTemplate = "#{privateStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    # browser
    #   .pause 2000
    #   .waitForElementVisible privateStacksSelector, 20000
    #   .waitForElementVisible stackTemplate, 20000


    draftStacksSelector  = '.HomeAppView--section.drafts'
    menuSelector         = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
    defaultStackSelector = '.SidebarTeamSection .SidebarStackSection.active h4'
    draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft'
    editSelector         = "#{menuSelector}:nth-of-type(1)"
    reinitSelector       = "#{menuSelector}:nth-of-type(2)"
    vmSelector           = "#{menuSelector}:nth-of-type(3)"
    sideBarSelector      = '#main-sidebar'
    headerTitleSelector  = '.SidebarSection-headerTitle'
    notificationSelector = '.kdnotification'
    plusIconSelector     = '.SidebarSection-secondaryLink'
    createStackEditor    = '.StackEditor-OnboardingModal'
    stackEditorView      = '.StackEditorView'
    reinitializeButton   = '.kdbutton.solid.red.medium'
    vmViewSelector       = '.kdview .kdtabpaneview .virtual-machines'

    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000

    #Test Stacks Title Click Events
      .click sideBarSelector
      .click headerTitleSelector
      .waitForElementVisible '.HomeAppView', 20000
      .pause 1000
      .click sideBarSelector
      .waitForElementVisible headerTitleSelector, 20000
      .moveToElement headerTitleSelector, 0, 0
      .waitForElementVisible plusIconSelector, 20000
      .click plusIconSelector
      .waitForElementVisible createStackEditor, 20000
      .pause 1000

    #Test Default Stack Settings Edit/Reinitialize/Vms
      .click sideBarSelector
      .waitForElementVisible defaultStackSelector, 20000
      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .pause 1000

      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click reinitSelector
      .waitForElementVisible '[testpath=reinitStack]', 20000
      .pause 3000
      .click reinitializeButton
      .waitForElementVisible notificationSelector, 20000
      .assert.containsText   notificationSelector, 'Reinitializing stack...'
      .pause 3000
      .click defaultStackSelector
      .waitForElementVisible menuSelector, 20000
      .pause 1000
      .click vmSelector
      .waitForElementVisible vmViewSelector, 20000
      .pause 2000

    #Test Draft Stack Settings Edit/Initialize
      .click sideBarSelector
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .pause 2000
      .click sideBarSelector
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click reinitSelector
      .waitForElementVisible notificationSelector, 20000
      .end()

