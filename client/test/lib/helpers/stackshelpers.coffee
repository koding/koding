teamsHelpers         = require '../helpers/teamshelpers.js'
helpers              = require '../helpers/helpers.js'
utils                = require '../utils/utils.js'
stackEditorUrl       = "#{helpers.getUrl(yes)}/Home/stacks"
async                = require 'async'
stackSelector        = null
sectionSelector      = '.kdview.kdtabpaneview.stacks'
newStackButton       = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
teamStacksSelector   = '.HomeAppView--section.team-stacks'
stackTemplate        = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"
draftStacksSelector  = '.HomeAppView--section.drafts'

module.exports =

  clickNewStackButton: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible sectionSelector, 20000
      .click newStackButton
      .pause 2000
      .assert.urlContains '/Stack-Editor/New'

  seeTeamStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000

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
      .waitForElementVisible stackTemplate, 20000
