kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
CommentInputWidget = require './commentinputwidget'
showError = require 'app/util/showError'
mixpanel = require 'app/util/mixpanel'
Encoder = require 'htmlencode'

module.exports = class CommentInputEditWidget extends CommentInputWidget

  constructor: (options = {}, data) ->

    options.cssClass    = kd.utils.curry 'edit-comment-box', options.cssClass
    options.editable    ?= yes
    options.showAvatar  ?= no

    super options, data

    @input.setValue Encoder.htmlDecode data.body


  initEvents: ->

    super

    @input.on 'EscapePerformed', @bound 'cancel'


  reset: ->

    @input.blur()
    @embedBox.resetEmbedAndHide()


  cancel: -> @emit 'Cancel'


  update: ({body}, callback) ->

    return  unless body.length

    @emit 'Submit'

    {id} = data = @getData()

    { appManager } = kd.singletons

    appManager.tell 'Activity', 'edit', {id, body}, (err) =>

      return showError err  if err

      data.body = body
      data.emit 'update'


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'EditFailed', err

    @emit 'EditSucceeded', activity

    mixpanel "Comment edit, success", { length: activity?.body?.length }


  viewAppended: ->

    super

    data         = @getData()
    {body, link} = data

    @input.setValue body, data

    @addSubView new KDCustomHTMLView
      cssClass  : 'cancel-description'
      pistachio : 'Press Esc to cancel'

    kd.utils.defer @bound 'setFocus'




