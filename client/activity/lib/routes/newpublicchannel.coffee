CreatePublicChannelModal = require 'activity/components/createpublicchannelmodal'
helper                   = require './helper'


module.exports = class NewChannelRoute

  constructor: ->

    @path = '/NewChannel'


  getComponents: (state, callback) ->

    helper.renderWithBackgroundChannel CreatePublicChannelModal, callback
