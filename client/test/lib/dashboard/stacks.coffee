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


    draftStacksSelector = '.HomeAppView--section.drafts'
    stackTemplate = "#{draftStacksSelector} .HomeAppViewListItem.StackTemplateItem"
    savedDefaultTemplate = ".SidebarSection.SidebarStackSection.draft a[href='#{stackSelector}']"
    removeFromSideBarButton = "#{stackTemplate} .HomeAppViewListItem-SecondaryContainer .HomeAppView--button.primary"

    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000
      .waitForElementVisible savedDefaultTemplate, 20000
      .url stackEditorUrl
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000
      .click removeFromSideBarButton
      .pause 2000
      .waitForElementNotPresent savedDefaultTemplate, 20000
      .click removeFromSideBarButton
      .waitForElementVisible savedDefaultTemplate, 20000
      .end()
