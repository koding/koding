class CommentInputEditWidget extends CommentInputWidget

  constructor: (options = {}, data) ->

    options.cssClass    = KD.utils.curry 'edit-comment-box', options.cssClass
    options.editable    ?= yes
    options.showAvatar  ?= no

    super options, data

    @input.setContent Encoder.htmlDecode data.body


  initEvents: ->

    super

    @input.on 'Escape', @bound 'cancel'


  reset: ->

    @input.blur()
    @embedBox.resetEmbedAndHide()


  cancel: -> @emit 'Cancel'


  update: ({body}, callback) ->

    return  unless body.length

    @emit 'Submit'

    {id} = data = @getData()

    { appManager } = KD.singletons

    appManager.tell 'Activity', 'edit', {id, body}, (err) =>

      return KD.showError err  if err

      data.body = body
      data.meta.updatedAt = new Date
      data.emit 'update'


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'EditFailed', err

    @emit 'EditSucceeded', activity

    KD.mixpanel "Comment edit, success", { length: activity?.body?.length }


  viewAppended: ->

    super

    @addSubView new KDCustomHTMLView
      cssClass  : 'cancel-description'
      pistachio : 'Press Esc to cancel'

    KD.utils.defer @bound 'setFocus'


