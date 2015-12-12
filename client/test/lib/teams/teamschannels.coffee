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

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser)
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


  leaveChannelOnSidebar: (browser) ->

    user        = teamsHelpers.loginTeam(browser)
    channelName = teamsHelpers.createChannel(browser, user)

    sidebarSectionsSelector      = '.activity-sidebar .SidebarSections'
    channelLinkOnSidebarSelector = "#{sidebarSectionsSelector} a[href='/Channels/#{channelName}']"

    teamsHelpers.leaveChannel(browser)
    teamsHelpers.createChannel(browser, user)

    browser
      .waitForElementVisible  sidebarSectionsSelector, 20000
      .assert.containsText    channelLinkOnSidebarSelector, channelName
      .end()
