kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
ActivityInputWidget = require '../activityinputwidget'
EmbedBoxWidget = require '../embedboxwidget'
ReplyInputView = require './replyinputview'
showError = require 'app/util/showError'


module.exports = class ReplyInputWidget extends ActivityInputWidget

  {noop, log} = kd

  constructor: (options = {}, data) ->

    options.cssClass       = kd.utils.curry 'reply-input-widget', options.cssClass
    options.placeholder    = ''
    options.inputViewClass = ReplyInputView

    super options, data

    @addSubView @input


  initEvents: ->
    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'
    @input.on 'keyup', (event) =>
      @showPreview() if @preview #Updates preview if it exists
      if event.keyCode is 38 and not event.altKey and @input.getValue().trim() is ''
        @emit 'EditModeRequested'

    @on 'SubmitStarted', => kd.utils.defer @bound 'focus'

  createSubViews: ->

    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass {defaultValue, placeholder}
    @embedBox = new EmbedBoxWidget delegate: @input, data
    @icon     = new KDCustomHTMLView tagName : 'figure'


  lockSubmit: -> @locked = yes


  unlockSubmit: -> @locked = no


  empty: -> @input.empty()

  # until we have a different type for collab messages - SY
  getPayload: ->
    return collaboration : yes  if @getOptions().collaboration
    super


  reset: (unlock = yes) ->

    @input.empty()
    @embedBox.resetEmbedAndHide()

    if unlock then @unlockSubmit()
    else kd.utils.wait 8000, @bound 'unlockSubmit'


  populatePayload: (url, callback = noop) ->

    options = { maxWidth: 475 }

    @embedBox.fetchEmbed url, options, (data = {}) =>

      payload = @applyPayload data

      callback null, payload


  # simplified version of the embed box implementation.
  # copied from EmbedBoxWidget, and changed it
  # to populate the payload directly
  # without needing to preview. ~U
  applyPayload: (data) ->

    return  unless data?

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data.safe? and not (data.safe is yes or data.safe is 'true')
      # In the case of unsafe data (most likely phishing), this should be used
      # to log the user, the url and other data to our admins.
      log 'There was unsafe content.', data, data.safe_type, data.safe_message
      return

    # to log the user, the url and other data to our admins.
    if data.error_message
      log 'EmbedBoxWidget encountered an error!', data.error_type, data.error_message
      return

    # types should be covered, but if the embed call fails partly, default to link
    type = data.type or 'link'

    return { link_url: data.url, link_embed: data }


  create: (options, callback) ->

    {channel: {id: channelId}} = @getOptions()

    options.channelId = channelId

    # text = @input.getValue()
    # urls = _.uniq (text.match @utils.botchedUrlRegExp) || []

    # if urls.length > 0 and not options.payload
    #   @populatePayload urls.first, (err, payload) =>
    #     options.payload = payload
    #     @sendPrivateMessage options, callback
    # else
    @sendPrivateMessage options, callback


  sendPrivateMessage: (options, callback) ->

    {appManager} = kd.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', options, (err, reply) =>
      return showError err  if err

      callback err, reply.first.lastMessage


  viewAppended: ->



