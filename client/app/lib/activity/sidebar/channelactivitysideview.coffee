kd                          = require 'kd'
ChannelSidebarMoreLink      = require './channelsidebarmorelink'
ActivitySideView            = require './activitysideview'


module.exports = class ChannelActivitySideView extends ActivitySideView

  constructor: (options = {}, data) ->

    super options, data


  createMoreLink: ->

    { searchLink, countSource, limit } = @getOptions()

    return new ChannelSidebarMoreLink {href: searchLink, countSource, limit}

