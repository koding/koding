BrowsePrivateChannelsModal = require 'activity/components/browsepublicchannelsmodal'

module.exports = class AllPrivateChannelsRoute

  constructor: ->

    @path = '/AllMessages'


  getComponent: (state, callback) -> callback null, BrowsePrivateChannelsModal


