BrowsePrivateChannelsModal = require 'activity/components/browseprivatechannelsmodal'

module.exports = class AllPrivateChannelsRoute

  constructor: ->

    @path = '/AllMessages'


  getComponent: (state, callback) -> callback null, BrowsePrivateChannelsModal


