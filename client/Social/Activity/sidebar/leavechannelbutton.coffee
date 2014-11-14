class LeaveChannelButton extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'leave-channel', options.cssClass
    options.title    = 'Delete'

    super options, data

    @setCallback @bound 'showModal'


  showModal: (event) ->

    KD.utils.stopDOMEvent event

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

    { SocialChannel } = KD.remote.api

    SocialChannel.delete { channelId: id }
      .then =>
        @deleteModal.destroy()
        KD.singletons.router.handleRoute '/Activity/Public'
      .catch (args...) =>
        KD.showError args...

