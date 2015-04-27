_  = require 'lodash'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
CommentInputWidget = require './commentinputwidget'
showError = require 'app/util/showError'
trackEvent = require 'app/util/trackEvent'
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
    @embedBox.close()


  cancel: -> @emit 'Cancel'


  update: ({body}, callback) ->

    return  unless body.length

    @emit 'Submit'

    {id, payload} = data = @getData()
    embedBoxPayload = @getEmbedBoxPayload()

    payload = _.assign {}, payload, embedBoxPayload

    { appManager } = kd.singletons

    appManager.tell 'Activity', 'edit', {id, body, payload}, (err, activity) =>

      return showError err  if err

      activity.body = body
      activity.link = payload

      activity.emit 'update'

      callback err, activity


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'EditFailed', err

    @emit 'EditSucceeded', activity

    trackEvent "Comment edit, success", { length: activity?.body?.length }


  viewAppended: ->

    super

    data         = @getData()
    {body, link} = data

    @input.setValue Encoder.htmlDecode body
    @input.emit 'BeingEdited', link?.link_url

    @addSubView new KDCustomHTMLView
      cssClass  : 'cancel-description'
      pistachio : 'Press Esc to cancel'

    kd.utils.defer @bound 'setFocus'




