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
    payload = @getPayload()

    { appManager } = kd.singletons

    appManager.tell 'Activity', 'edit', {id, body, payload}, (err, activity) =>

      return showError err  if err

      activity.body = body

      if payload
        activity.link.link_url = payload.link_url
        activity.link.link_embed = payload.link_embed

      activity.emit 'update'

      callback err, activity


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'EditFailed', err

    @emit 'EditSucceeded', activity

    mixpanel "Comment edit, success", { length: activity?.body?.length }


  getPayload: ->

    link_url   = @embedBox.url
    link_embed = @embedBox.getDataForSubmit()

    return {link_url, link_embed}  if link_url and link_embed


  viewAppended: ->

    super

    data         = @getData()
    {body, link} = data

    @input.setValue body, data
    @embedBox.loadEmbed link.link_url  if link

    @addSubView new KDCustomHTMLView
      cssClass  : 'cancel-description'
      pistachio : 'Press Esc to cancel'

    kd.utils.defer @bound 'setFocus'




