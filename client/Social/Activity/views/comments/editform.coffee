class CommentEditForm extends CommentInputForm

  constructor: (options = {}, data) ->

    options.cssClass    = KD.utils.curry 'edit-comment-box', options.cssClass
    options.editable    ?= yes
    options.showAvatar  ?= no

    super options, data

    @input.setValue Encoder.htmlDecode data.body
    @input.on 'EscapePerformed', @bound 'cancel'


  enter: (body) ->

    return  unless body.length

    @emit 'Submit'

    {id} = data = @getData()

    KD.singleton('appManager').tell 'Activity', 'edit', {id, body}, (err) =>

      return KD.showError err  if err

      data.body = body
      data.meta.updatedAt = new Date
      data.emit 'update'


  cancel: -> @emit 'Cancel'


  viewAppended: ->

    super

    @addSubView new KDCustomHTMLView
      cssClass  : 'cancel-description'
      pistachio : 'Press Esc to cancel'

    KD.utils.defer =>

      @input.setFocus()
      @input.resize()
