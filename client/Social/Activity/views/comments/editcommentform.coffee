class EditCommentForm extends NewCommentForm

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "edit-comment-box", options.cssClass
    options.editable ?= yes

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass  : "cancel-description"
      pistachio : "Press Esc to cancel"

    @input.setValue Encoder.htmlDecode data.body
    @input.on "EscapePerformed", @bound "cancel"


  submit: ->

    body = @input.getValue().trim()

    return  unless body.length

    @emit "Submit"

    {id} = data = @getData()

    KD.singleton("appManager").tell "Activity", "edit", {id, body}, (err) =>

      return KD.showError err  if err

      data.body = body
      data.meta.updatedAt = new Date
      data.emit "update"


  cancel: ->

    @emit "Cancel"


  viewAppended: ->

    super

    KD.utils.defer =>

      @input.setFocus()
      @input.resize()
