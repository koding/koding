class EditCommentForm extends NewCommentForm

  constructor: (options = {}, data) ->

    options.editable = yes

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass  : "cancel-description"
      pistachio : "Press Esc to cancel"

    @input.setValue Encoder.htmlDecode data.body
    @input.on "EscapePerformed", @bound "cancel"


  submit: ->

    @getDelegate().emit 'CommentUpdated', @input.getValue()


  cancel: ->

    @getDelegate().emit "CommentUpdateCancelled"


  viewAppended: ->

    super

    KD.utils.defer =>

      @input.setFocus()
      @input.resize()
