utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
activityHelpers      = require '../helpers/activityhelpers.js'

post        = 'Testing Most Recent post 2'
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


  # createPostAndCheckThatItsDisplayedInRealTime: (browser) ->

  #   console.log " ✔ Starting activity test..."
  #   console.log " ✔ Host: #{host.username}"
  #   console.log " ✔ Participant: #{participant.username}"

  #   hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

  #   if hostBrowser
  #     startSession browser, host, participant
  #     helpers.doPostActivity browser, post
  #   else
  #     joinSession browser, host, participant
  #     activityHelpers.assertPostOnSecondSession browser, post

  #   browser.end()


  createPostAndCheckUnreadCounts: (browser) ->

    console.log " ✔ Starting activity test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      startSession browser, host, participant
      activityHelpers.joinChat browser
      browser
        .pause  5000 #for the topic to be saved
        .waitForElementVisible  '.kdmodal-inner .close-icon.closeModal', 20000
        .click                  '.kdmodal-inner .close-icon.closeModal'
        .waitForElementVisible  '.kdlistview-activities .clearfix:nth-of-type(3)', 20000
        .click                  '.kdlistview-activities .clearfix:nth-of-type(3)'
        .waitForElementVisible  '[testpath=ActivityInputView]', 20000
        .click                  '[testpath=ActivityInputView]'
        .setValue               '[testpath=ActivityInputView]', 'Testing with swagg'
        .click                  '.widget-button-bar button'
        .pause                  1000
        .setValue               '[testpath=ActivityInputView]', 'Testing with swagg'
        .click                  '.widget-button-bar button'
        .pause                  1000
        .setValue               '[testpath=ActivityInputView]', 'Testing with swagg'
        .click                  '.widget-button-bar button'
        .pause                  1000
        .end()

    else
      joinSession browser, host, participant
      activityHelpers.joinChat browser
      browser
        .pause  5000 #for the topic to be saved
        .waitForElementVisible  '.kdmodal-inner .close-icon.closeModal', 20000
        .click                  '.kdmodal-inner .close-icon.closeModal'
        .pause					7500
        .waitForElementVisible  '.kdlistview-activities .unread .count', 20000
      
      browser.assert.containsText('.kdlistview-activities .unread .count', 3);
      browser.end()
