ChannelSidebarMoreLink = require './channelsidebarmorelink'
ActivitySideView       = require './activitysideview'


module.exports = class ChannelActivitySideView extends ActivitySideView

  createMoreLink: ->

    { searchLink, countSource, limit } = @getOptions()

    return new ChannelSidebarMoreLink { href: searchLink, countSource, limit }
