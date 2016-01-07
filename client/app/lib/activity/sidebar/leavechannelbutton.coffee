remote = require('../../remote').getInstance()
showError = require '../../util/showError'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDModalView = kd.ModalView
module.exports = class LeaveChannelButton extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'leave-channel', options.cssClass
    options.title    = 'Delete'

    super options, data

    @setCallback @bound 'showModal'


  showModal: (event) ->

    kd.utils.stopDOMEvent event

    @deleteModal = KDModalView.confirm
      title : 'Are you sure'
      content : 'Delete this message?'
      ok :
        title: 'Remove'
        callback : @bound 'delete'


  delete: (event) ->

    { id } = @getData()
    removeButton = @deleteModal.buttons['OK']
    removeButton.showLoader()

    { SocialChannel } = remote.api

    SocialChannel.delete { channelId: id }
      .then =>
        @deleteModal.destroy()
        kd.singletons.router.handleRoute '/Activity/Public'
      .catch (args...) =>
        showError args...
