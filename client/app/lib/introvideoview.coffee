kd = require 'kd'
globals = require 'globals'
JView = require 'app/jview'
{ actions : HomeActions } = require 'home/flux'

VIDEO_SRC = 'https://www.youtube.com/embed/hR3mUvknsaU?autoplay=1'

module.exports = class IntroVideoView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'IntroVideoView'

    super options, data

    @checkbox = new kd.CustomCheckBox
    @label = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'IntroVideoView--label'
      partial  : 'Don\'t show me this again'
      click    : => @checkbox.setValue not @checkbox.getValue()


  click: (event) ->

    if event.target.classList.contains 'IntroVideoView-SkipLink'
      kd.utils.stopDOMEvent event
      kd.singletons.mainView.hideIntroVideo()
    else if event.target.classList.contains 'IntroVideoView-FauxVideo'
      @$('.IntroVideoView-FauxVideo').addClass 'hidden'
      @$('.IntroVideoView-Video').removeClass 'hidden'
      @$('.IntroVideoView-Video iframe').attr 'src', VIDEO_SRC
    else if event.target.classList.contains 'GenericButton'
      HomeActions.markAsDone 'watchVideo'  if @checkbox.getValue()
      kd.singletons.mainView.hideIntroVideo()


  pistachio: ->
    """
    <section class='IntroVideoView--wrapper'>
      <h1 class='IntroVideoView-Title'>Welcome to Koding.</h1>
      <h2 class='IntroVideoView-Subtitle'>You are all set. We would recommend you to watch our short video to know how to use Koding.</h2>
      <figure class='IntroVideoView-VideoWrapper'>
        <div class='IntroVideoView-FauxVideo'>
          Watch this <strong>30 seconds video</strong>
        </div>
        <div class='IntroVideoView-Video hidden'>
          <iframe width="640" height="400" frameborder="0" allowfullscreen></iframe>
          <div class='IntroVideoView-Video--actions'>
            {{> @checkbox}} {{> @label}}
            <button class='GenericButton'>CLOSE</button>
          </div>
        </div>
      </figure>
      <a class='IntroVideoView-SkipLink' href='#'>Skip this video</a>
    </section>
    """
