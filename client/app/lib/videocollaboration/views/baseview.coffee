kd = require 'kd'
getNick = require 'app/util/nick'
VideoControlView = require './controlview'

module.exports = class ChatVideoView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ChatVideo', options.cssClass

    super options, data

    @publisherView = null

    @createContainer()
    @createControls()


  createContainer: ->

    @container = new kd.CustomHTMLView { cssClass: 'ChatVideo-container' }
    @addSubView @container


  createControls: ->

    @controls = new kd.CustomHTMLView { cssClass: 'ChatVideo-controls' }

    @controlAudio = createVideoControl 'audio', no
    @controlAudio.on 'ActiveStateChanged', @handleStateChanged 'audio'

    @controlVideo = createVideoControl 'video', no
    @controlVideo.on 'ActiveStateChanged', @handleStateChanged 'video'

    # TODO: if user is host
    @controlEnd = createVideoControl 'end', no
    @controlEnd.on 'ActiveStateChanged', @handleStateChanged 'end'

    @controls.addSubView @controlAudio
    @controls.addSubView @controlVideo
    @controls.addSubView @controlEnd

    @addSubView @controls


  getContainer: -> @container


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
  new VideoControlView { cssClass, active }


