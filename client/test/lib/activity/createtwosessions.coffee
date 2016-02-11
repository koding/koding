utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
activityHelpers      = require '../helpers/activityhelpers.js'

post = 'Testing Most Recent post'


startSession = (browser, firstUser, secondUser) ->

  helpers.beginTest browser, firstUser
  helpers.doPostActivity browser, post


joinSession = (browser, firstUser, secondUser) ->

  helpers.beginTest browser, secondUser
  activityHelpers.assertPostOnSecondSession browser, post


module.exports =

  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    if utils.suiteHookHasRun 'before'
    then return
    else utils.registerSuiteHook 'before'


  createPostAndCheckThatItsDisplayedInRealTime: (browser) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    console.log " ✔ Starting activity test..."
    console.log " ✔ Host: #{host.username}"
    console.log " ✔ Participant: #{participant.username}"

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      startSession browser, host, participant
    else
      joinSession browser, host, participant

    browser.end()