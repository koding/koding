class LeaveChannelButton extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'leave-channel', options.cssClass
    options.title    = 'Delete'

    super options, data

    @setCallback @bound 'delete'


  delete: (event) ->

    KD.utils.stopDOMEvent event

    PrivateMessageDeleteModal.create @getData()


