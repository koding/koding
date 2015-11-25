CreatePrivateChannelModal = require 'activity/components/createprivatechannelmodal'
helper = require './helper'

module.exports = class NewPrivateChannelRoute

  constructor: ->

    @path = '/NewMessage'


  getComponents: (state, callback) ->

    helper.renderWithBackgroundChannel CreatePrivateChannelModal, callback


