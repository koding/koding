helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'

sidebarSectionsSelector = '.activity-sidebar .SidebarSections'

module.exports =


  createChannel: (browser) ->

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    browser.end()


  createChannelWithPurpose: (browser) ->
 
    purpose = "testing the purpose field"
 
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user, null, null, purpose)
    browser.end()
 
 
  updateChannelPurpose: (browser) ->
  
    purpose = "testing the purpose field"
 
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user, null, null, purpose)
    teamsHelpers.updateChannelPurpose(browser)
    browser.end()


  sendComment: (browser) ->

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


  switchBetweenYourChannelsAndOtherChannels: (browser) ->
 
    sidebarSelector          = '.SidebarChannelsSection .SidebarSection-header'
    channelTextSelector      = '.ChannelList-Modal.PublicChannelListModal .ChannelListWrapper .ChannelList-title'
    otherChannelsTabSelector = '.ChannelListWrapper .ChannelList-tabs .ChannelList-tab:nth-of-type(2)'
    activeTabSelector        = '.ChannelListWrapper .ChannelList-tabs .ChannelList-tab.active-tab'
    otherChannelsJoinButton  = '.PublicChannelLink.ChannelListItem .Button'
 
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.leaveChannel(browser)
  
    browser
      .waitForElementVisible  sidebarSelector, 20000
      .click                  sidebarSelector
      .waitForElementVisible  channelTextSelector, 20000
      .assert.containsText    channelTextSelector, 'Channels'
      .waitForElementVisible  otherChannelsTabSelector, 20000
      .click                  otherChannelsTabSelector
      .waitForElementVisible  activeTabSelector, 20000
      .waitForElementVisible  otherChannelsJoinButton, 20000
      .assert.containsText    otherChannelsJoinButton, 'JOIN'
      .end()
 
 
  leaveChannel: (browser) ->

    user                    = teamsHelpers.loginTeam(browser)
    channelName1            = teamsHelpers.createChannel(browser, user)
    sidebarSectionsSelector = '.activity-sidebar .SidebarChannelsSection'

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
