class KDWebcamView extends JView

  constructor: (options={}, data)->

    options.cssClass    or= "kdwebcamview"
    options.screenFlash  ?= yes

    options.snapTitle   or= "Snap Photo"
    options.resnapTitle or= "Resnap"
    options.saveTitle   or= "Save"

    options.countdown    ?= 3

    super options, data

    @attachEvents()

    @video = new KDCustomHTMLView
      tagName   : "video"
      attributes:
        autoplay: yes

    @picture = new KDCustomHTMLView
      tagName   : "canvas"

    @button = new KDButtonView
      title     : options.snapTitle
      cssClass  : "snap-button hidden"
      callback  : @bound 'countDown'

    @retake = new KDButtonView
      title     : options.resnapTitle
      cssClass  : "snap-button retake hidden"
      callback  : => @resetView()


    @save = new KDButtonView
      title     : options.saveTitle
      cssClass  : "snap-button save hidden"
      callback  : =>
        @resetView()
        @video.setClass "invisible"
        @button.hide()
        @emit "save"

  attachEvents: ->

    {snapTitle} = @getOptions()

    @on "KDObjectWillBeDestroyed", => @unsetVideoStream()

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

    @on "countDownEnd", =>
      @button.hide()
      @retake.show()
      @save.show()
      @takePicture()
      @button.setTitle snapTitle

  resetView: ->
    @button.show()
    @retake.hide()
    @save.hide()
    @reset()

  reset: ->
    @video.unsetClass "invisible"

  countDown: ->
    {countdown} = @getOptions()

    if countdown > 0
      counter = =>
        @button.setTitle countdown
        countdown--

      count = @utils.repeat 1000, counter
      do counter

      timer = @utils.wait (countdown+1)*1000, =>
        @utils.killRepeat count
        @utils.killWait timer
        @emit "countDownEnd"
    else
      @emit "countDownEnd"

  autoResize: ->
    video = @video.getElement()
    size  =
      width : video.clientWidth
      height: video.clientHeight

    @picture.setDomAttributes size
    @setSize size

  unsetVideoStream: ->
    video = @video.getElement()
    video.pause()
    KDWebcamView.setVideoStreamVendor video, ""
    @localMediaStream?.stop()

  setVideoStream: (stream)->
    video = @video.getElement()
    KDWebcamView.setVideoStreamVendor video, stream
    video.play()
    video.addEventListener "playing", =>
      @show()
      @button.show()
      @autoResize()

  @setVideoStreamVendor: (video, stream)->
    if video.mozSrcObject isnt undefined
    then video.mozSrcObject = stream
    else video.src = stream

  @getUserMediaVendor: ->
    navigator.getUserMedia or\
    navigator.webkitGetUserMedia or\
    navigator.mozGetUserMedia

  @getURLVendor: ->
    window.URL or\
    window.webkitURL or\
    window.mozURL

  getUserMedia: ->
    _onError = (error)=> @emit "error", error
    navigator.getUserMedia = KDWebcamView.getUserMediaVendor()
    window.URL = KDWebcamView.getURLVendor()

    if navigator.getUserMedia
      navigator.getUserMedia video: yes, (stream)=>
        @localMediaStream = stream
        @setVideoStream (window.URL and window.URL.createObjectURL stream) or stream
      , _onError
    else _onError notSupported: yes

  flash: ->
    flash  = new KDView
      cssClass: "kdwebcamview-flash"

    KDView.appendToDOMBody flash
    KD.utils.defer ->
      flash.setClass "flashed"
      KD.utils.wait 500, -> flash.destroy()

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
    {{> @save}}
    {{> @retake}}
    {{> @video}}
    {{> @picture}}
    """