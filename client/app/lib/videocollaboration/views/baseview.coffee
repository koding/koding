kd = require 'kd'
getNick = require 'app/util/nick'
VideoControlView = require './controlview'
isMyChannel = require 'app/util/isMyChannel'
NoiseView = require 'app/commonviews/noiseview'

module.exports = class ChatVideoView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ChatVideo', options.cssClass

    super options, data

    @publisherView = null

    @createContainer()
    @createOfflineUserContainer()
    @createCameraDialogContainer()
    @createControls()


  createContainer: ->

    @container = new kd.CustomHTMLView { cssClass: 'ChatVideo-container' }
    @addSubView @container


  createOfflineUserContainer: ->

    @offlineUserContainer = createAbsoluteContainer 'ChatVideo-offlineUserContainer'
    @addSubView @offlineUserContainer


  createCameraDialogContainer: ->

    cssClass = 'ChatVideo-cameraDialogContainer hidden'
    @cameraDialogContainer = createAbsoluteContainer cssClass

    title = k 'span', 'title'
    title.updatePartial 'Default text'

    @cameraDialogContainer.title = title
    @cameraDialogContainer.addSubView title

    @addSubView @cameraDialogContainer



  createControls: ->

    @controls = new kd.CustomHTMLView { cssClass: 'ChatVideo-controls' }

    @controlAudio = createVideoControl 'audio', no
    @controlAudio.on 'ActiveStateChangeRequested', @handleStateChangeRequest 'audio'
    @controls.addSubView @controlAudio

    @controlVideo = createVideoControl 'video', no
    @controlVideo.on 'ActiveStateChangeRequested', @handleStateChangeRequest 'video'
    @controls.addSubView @controlVideo

    if isMyChannel @getData()
      @controlEnd = createVideoControl 'end', no
      @controlEnd.on 'ActiveStateChangeRequested', @handleStateChangeRequest 'end'
      @controls.addSubView @controlEnd

    @addSubView @controls


  getContainer: -> @container


  getOfflineUserContainer: -> @offlineUserContainer


  getCameraDialogContainer: -> @cameraDialogContainer


  showCameraDialog: (title) ->

    width = 325
    height = 265

    @_noiseView = new NoiseView { size: { width, height } }

    @cameraDialogContainer.addSubView @_noiseView

    @cameraDialogContainer.title.updatePartial title  if title?
    @cameraDialogContainer.show()


  hideCameraDialog: ->

    @_noiseView.destroy()
    @_noiseView = null

    @cameraDialogContainer.hide()


  ###*
   * This method needs to be overriden by subclasses.
   *
   * @abstract
  ###
  handleStateChangeRequest: (type) -> (active) -> throw new Error 'needs to be implemented'


  show: ->

    @emit 'ViewWillShow'

    super

    @emit 'ViewDidShow'


  hide: ->

    @emit 'ViewWillHide'

    super

    @emit 'ViewDidHide'


createVideoControl = (type, active) ->

  cssClass = "ChatVideoControl ChatVideoControl--#{type}"

  title = switch type
    when 'video'
      activeTooltipText = 'Turn-off Camera'
      deactiveTooltipText = 'Turn-on Camera'
    when 'audio'
      activeTooltipText = 'Mute'
      deactiveTooltipText = 'Unmute'
    when 'end'
      activeTooltipText = 'End session'
      deactiveTooltipText = 'End session'

  new VideoControlView { cssClass, active, activeTooltipText, deactiveTooltipText }


createAbsoluteContainer = (cssClass) -> k 'div', "ChatVideo-absoluteContainer #{cssClass}"


###*
 * Create a KDView with given tag, css class, and subviews.
 *
 * @param {string} tagName
 * @param {string} cssClass
 * @param {Array.<(KDView|string)>} subviews
###
k = (tagName, cssClass, subviews = []) ->

  view = new kd.CustomHTMLView { tagName, cssClass }

  for subview in subviews
    if 'string' is typeof subview
    then view.setPartial subview
    else view.addSubView subview

  return view


