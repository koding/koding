BrowsePublicChannelsModal = require 'activity/components/browsepublicchannelsmodal'
helper = require './helper'

module.exports = class AllPublicChannelsRoute

  constructor: ->

    @path = '/AllChannels'


  getComponents: (state, callback) ->

    helper.renderWithBackgroundChannel BrowsePublicChannelsModal.Container, callback
