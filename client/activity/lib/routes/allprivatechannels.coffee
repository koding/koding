BrowsePrivateChannelsModal = require 'activity/components/browseprivatechannelsmodal'
helper = require './helper'

module.exports = class AllPrivateChannelsRoute

  constructor: ->

    @path = '/AllMessages'


  getComponents: (state, callback) ->

    helper.renderWithBackgroundChannel BrowsePrivateChannelsModal, callback
