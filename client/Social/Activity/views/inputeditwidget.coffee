class ActivityEditWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'edit-widget', options.cssClass
    options.destroyOnSubmit = yes

    super options, data

  viewAppended: ->

    data         = @getData()
    {body, link} = data

    @input.setValue Encoder.htmlDecode body
    @embedBox.loadEmbed link.link_url  if link

    @addSubView @input
    @addSubView @embedBox
