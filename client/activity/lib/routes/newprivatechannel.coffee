CreatePrivateChannelModal = require 'activity/components/createprivatechannelmodal'

module.exports = class NewPrivateChannelRoute

  constructor: ->

    @path = '/NewMessage'


  getComponent: (state, callback) -> callback null, CreatePrivateChannelModal
