helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'

sidebarSectionsSelector = '.activity-sidebar .SidebarSections'

module.exports =


  createNewChannelWithInvalidName: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user, '{invalid-name}', yes)
    browser.end()


  postLongMessage: (browser) ->

    message  = ''
    message += helpers.getFakeText() for [1..6]

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    browser.end()


  postMessageWithCode: (browser) ->

    messageWithFullCode = "```console.log('123456789')```"

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, messageWithFullCode, 'messageWithCode')
    browser.end()


  postMessageWithImage: (browser) ->

    image = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.333.png Hello World"

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, image, 'messageWithImage')
    browser.end()


  postMessageWithLink: (browser) ->

    link = 'http://wikipedia.org Hello World'

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, link, 'messageWithLink')
    browser.end()


  postMessageWithBlockquote: (browser) ->
  
    message = "> Message with blockquote"
  
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message, 'messageWithBlockquote')
    browser.end()
  
 
  # postMessageWithEmoji: (browser) ->

  #   messageWithEmoji = ':smiley: :+1:'

  #   user = teamsHelpers.loginTeam(browser)
  #   teamsHelpers.createChannel(browser, user)
  #   teamsHelpers.sendComment(browser, messageWithEmoji, 'messageWithEmoji')
  #   browser.end()
