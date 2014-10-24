class ReplyInputEditWidget extends ReplyInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'edit-widget', options.cssClass
    options.destroyOnSubmit = yes

    super options, data

    @unsetClass 'reply-input-widget'

    { body } = @getData()

    @input.setValue Encoder.htmlDecode body


