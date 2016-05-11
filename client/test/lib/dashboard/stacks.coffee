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
      teamsHelpers.createCredential browser, 'aws', 'test credential' no,  ->
        teamsHelpers.createStack browser, ->
          done()


  redirectStackTemplate: (browser) ->

    sectionSelector = '.kdview.kdtabpaneview.stacks'
    newStackButton = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
    host = utils.getUser()
    url = helpers.getUrl(yes)
    browser.url url, ->
      teamsHelpers.loginToTeam browser, host, no, ->
        browser
          .pause 2000
          .url stackEditorUrl
          .waitForElementVisible sectionSelector, 20000
          .click newStackButton, ->
            helpers.switchBrowser browser, 'Stack-Editor/New'


  teamStacks: (browser) ->

    teamStacksSelector = '.HomeAppView--section.team-stacks'
    stackTemplate = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    host = utils.getUser()
    url = helpers.getUrl(yes)
    browser.url url, ->
      teamsHelpers.loginToTeam browser, host, no, ->
        browser
          .pause 2000
          .url stackEditorUrl
          .waitForElementVisible teamStacksSelector, 20000
          .waitForElementVisible stackTemplate, 20000
          .end()


  privateStacks: (browser) ->

    privateStacksSelector = '.HomeAppView--section.private-stacks'
    stackTemplate = "#{privateStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    host = utils.getUser()
    url = helpers.getUrl(yes)
    browser.url url, ->
      teamsHelpers.loginToTeam browser, host, no, ->
        browser
          .pause 2000
          .url stackEditorUrl
          .waitForElementVisible privateStacksSelector, 20000
          .waitForElementVisible stackTemplate, 20000
          .end()


  draftStacks: (browser) ->

    draftStacksSelector = '.HomeAppView--section.drafts'
    stackTemplate = "#{draftStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    host = utils.getUser()
    url = helpers.getUrl(yes)
    browser.url url, ->
      teamsHelpers.loginToTeam browser, host, no, ->
        browser
          .pause 2000
          .url stackEditorUrl
          .waitForElementVisible draftStacksSelector, 20000
          .waitForElementVisible stackTemplate, 20000
          .end()

