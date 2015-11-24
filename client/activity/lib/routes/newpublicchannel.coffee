CreatePublicChannelModal = require 'activity/components/createpublicchannelmodal'
helper = require './helper'

ChannelThreadPane = require 'activity/components/channelthreadpane'

module.exports = class NewChannelRoute

  constructor: ->

    @path = '/NewChannel'


  getComponents: (state, callback) ->

    helper.renderWithBackgroundChannel CreatePublicChannelModal, callback


