CreatePublicChannelModal = require 'activity/components/createpublicchannelmodal'

module.exports = class NewChannelRoute

  constructor: ->

    @path = '/NewChannel'


  getComponent: (state, callback) -> callback null, CreatePublicChannelModal


