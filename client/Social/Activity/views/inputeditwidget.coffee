class ActivityEditWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry "edit-widget", options.cssClass
    options.destroyOnSubmit = yes

    super options, data

    @submitButton = new KDButtonView
      title       : "Done editing"
      type        : "submit"
      cssClass    : "solid green"
      loader      : yes
      callback    : @bound "submit"

    @cancelButton = new KDButtonView
      title    : "Cancel"
      cssClass : "solid gray"
      callback : => @emit "Cancel"


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
    @input.addSubView @submitButton
    @input.addSubView @cancelButton
