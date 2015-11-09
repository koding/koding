BrowsePublicChannelsModal = require 'activity/components/browsepublicchannelsmodal'

module.exports = class AllPublicChannelsRoute

  constructor: ->

    @path = '/AllChannels'


  getComponent: (state, callback) -> callback null, BrowsePublicChannelsModal

