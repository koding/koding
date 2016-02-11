utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
activityHelpers      = require '../helpers/activityhelpers.js'

host        = utils.getUser no, 0
participant = utils.getUser no, 1

startSession = (browser, firstUser, secondUser) ->

  helpers.beginTest browser, firstUser


joinSession = (browser, firstUser, secondUser) ->

  helpers.beginTest browser, secondUser


module.exports =

  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    if utils.suiteHookHasRun 'before'
    then return
    else utils.registerSuiteHook 'before'


  createPostAndCheckThatItsDisplayedInRealTime: (browser) ->

    console.log " ✔ Starting activity test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    post        = 'Dummy Text - Testing Latest Post'

    if hostBrowser
      startSession browser, host, participant
      helpers.doPostActivity browser, post
      browser.end()
    else
      joinSession browser, host, participant
      activityHelpers.assertPostOnSecondSession browser, post

    browser.end()


  createPostAndCheckUnreadCounts: (browser) ->

    console.log " ✔ Starting activity test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    numberOfUnreadMessages = '.kdlistview-activities .unread .count'
    channelSelector        = '.kdlistview-activities .clearfix:nth-of-type(3)'
    textSelector           = '[testpath=ActivityInputView]'
    post                   = '#createChannel'
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      startSession browser, host, participant
      helpers.doPostActivity browser, post
      activityHelpers.joinChat browser
      browser
        .waitForElementVisible  channelSelector, 20000
        .click                  channelSelector
        .waitForElementVisible  textSelector, 20000
        .click                  textSelector
    
      activityHelpers.simpleMessagePost browser for i in [0...5]
      browser.end()

    else
      joinSession browser, host, participant
      activityHelpers.joinChat browser

      browser.expect.element(numberOfUnreadMessages).text.to.equal(5).before(50000);
      browser.assert.containsText(numberOfUnreadMessages, 5);
      browser.end()