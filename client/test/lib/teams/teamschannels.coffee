helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'

sidebarSectionsSelector = '.activity-sidebar .SidebarSections'

module.exports =


  createChannel: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    browser.end()


  sendComment: (browser) ->
    message = helpers.getFakeText()

    message = helpers.getFakeText()

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    browser.end()


  checkChannelList: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannelsAndCheckList(browser, user)
    browser.end()


  searchChannels: (browser) ->

    channelListModal    = '.ChannelList-Modal'
    searchInputSelector = "#{channelListModal} .ChannelList-searchInput"
    threadsContainer    = "#{channelListModal} .SidebarModalThreads"

    user         = teamsHelpers.loginTeam(browser)
    channelNames = teamsHelpers.createChannelsAndCheckList(browser, user)

    browser
      .waitForElementVisible  searchInputSelector, 20000
      .setValue               searchInputSelector, channelNames[0].slice 0, 8
      .assert.containsText    threadsContainer, channelNames[0]
      .end()


  leaveChannel: (browser) ->

    user                    = teamsHelpers.loginTeam(browser)
    channelName1            = teamsHelpers.createChannel(browser, user)
    sidebarSectionsSelector = '.activity-sidebar .SidebarSections'

    teamsHelpers.leaveChannel(browser)
    channelName2                  = teamsHelpers.createChannel(browser, user)
    channelLinkOnSidebarSelector2 = "#{sidebarSectionsSelector} a[href='/Channels/#{channelName2}']"

    browser
      .waitForElementVisible  sidebarSectionsSelector, 20000
      .expect.element(sidebarSectionsSelector).text.to.not.contain(channelName1)

    browser
      .assert.containsText    channelLinkOnSidebarSelector2, channelName2
      .end()


  joinChannel: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.joinChannel(browser)
    browser.end()


  createNewChannelWithInvalidName: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user, '{invalid-name}', yes)
    browser.end()


  postLongMessage: (browser) ->
    message  = ''
    message += helpers.getFakeText() for [1..6]

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


  postMessageWithEmoji: (browser) ->

    messageWithEmoji = ':smiley: :+1:'

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, messageWithEmoji, 'messageWithEmoji')
    browser.end()
    