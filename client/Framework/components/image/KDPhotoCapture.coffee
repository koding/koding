class KDPhotoCapture extends JView

  constructor: (options={}, data)->

    options.cssClass    or= "kdphotocapture"
    options.screenFlash or= yes

    super options, data

    @on "viewAppended", =>
      @context = @picture.getElement().getContext "2d"
      @getUserMedia()

    @on "error", (error)->
      @setClass "forbidden"
      new KDNotificationView
        type    : "tiny"
        title   : "Your browser doesn't allow to use camera."

    @on "snap", =>
      @video.setClass "invisible"

    @video = new KDCustomHTMLView
      tagName   : "video"
      attributes:
        autoplay: yes

    @picture = new KDCustomHTMLView
      tagName   : "canvas"

    @button = new KDButtonView
      title     : "Snap Photo"
      cssClass  : "snap-photo-button hidden"
      callback  : =>
        @button.hide()
        @retake.show()
        @takePicture()

    @retake = new KDButtonView
      title     : "Resnap"
      cssClass  : "snap-photo-retake hidden"
      callback  : =>
        @button.show()
        @retake.hide()
        @reset()

  reset: ->
    @video.unsetClass "invisible"

  autoResize: ->
    video = @video.getElement()
    size  =
      width : video.clientWidth
      height: video.clientHeight

    @picture.setDomAttributes size
    @setSize size

  setVideoStream: (stream)->
    video = @video.getElement()
    video.src = stream
    video.play()
    video.addEventListener "playing", =>
      @show()
      @button.show()
      @autoResize()

  getUserMedia: ->
    _onError = (error)=> @emit "error", error
    if navigator.getUserMedia
      navigator.getUserMedia video: yes, (stream)=>
        @setVideoStream stream
      , _onError
    else
      navigator.webkitGetUserMedia video: yes, (stream)=>
        @setVideoStream window.webkitURL.createObjectURL stream
      , _onError

  flash: ->
    flash  = new KDView
    $flash = flash.$()
    $flash.css
      zIndex          : 10002
      backgroundColor : "#ffffff"
      position        : "absolute"
      top             : 0
      left            : 0
      opacity         : 0.95
    KDView.appendToDOMBody flash
    $flash.fadeOut -> flash.destroy()

  takePicture: ->
    video   = @video.getElement()
    picture = @picture.getElement()

    {screenFlash} = @getOptions()
    @flash() if screenFlash
    @autoResize()

    @context.drawImage video, 0, 0, video.clientWidth, video.clientHeight
    @emit "snap", picture.toDataURL(), picture

  pistachio: ->
    """
    {{> @button}}
    {{> @retake}}
    {{> @video}}
    {{> @picture}}
    """