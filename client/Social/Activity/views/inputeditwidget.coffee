class ActivityEditWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry "edit-widget", options.cssClass
    options.destroyOnSubmit = yes

    super options, data

  viewAppended: ->

    data         = @getData()
    {body, link} = data
    content      = ""

    for line in body.split "\n"
      content += "<div>#{Encoder.htmlEncode line}&nbsp;</div>"

    @input.setContent content, data
    @embedBox.loadEmbed link.link_url  if link

    @addSubView @input
    @addSubView @embedBox
