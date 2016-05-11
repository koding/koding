teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
stackEditorUrl = "#{helpers.getUrl(yes)}/Home/stacks"


module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users =
      targetUser1

    teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
      teamsHelpers.createCredential browser, 'aws', 'test credential', no,  ->
        teamsHelpers.createStack browser, ->
          done()


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
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000


    privateStacksSelector = '.HomeAppView--section.private-stacks'
    stackTemplate = "#{privateStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    browser
      .pause 2000
      .waitForElementVisible privateStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000


    draftStacksSelector = '.HomeAppView--section.drafts'
    stackTemplate = "#{draftStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000


    stackTemplate = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    browser
      .pause 2000
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000
      .click stackTemplate
      .waitForElementVisible '.kdview.StackEditorView', 20000
      .end()
