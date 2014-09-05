class OnboardingModalContent extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'content-container'

    super options, data

    @getStartedButton = new KDButtonView
      title     : 'Get Started'
      cssClass  : 'get-started solid green medium'
      callback  : => @emit 'GetStartedButtonClicked'

    @videoPlaceholder = new KDCustomHTMLView
      cssClass : 'video-placeholder'
      click    : _.once @bound 'startVideo'

    @videoPlaceholder.addSubView @video = new JView
      tagName    : 'video'
      attributes : controls: on
      pistachio  :
        """
        <source src='https://koding-cdn.s3.amazonaws.com/movies/introduction.webm'>
        <source src='https://koding-cdn.s3.amazonaws.com/movies/introduction.mp4'>
        """


  startVideo: ->
    @videoPlaceholder.setClass 'started'
    @video.getElement().play()


  pistachio: ->
    """
      <div class="top-container">
        {{> @videoPlaceholder}}
      </div>
      <div class="footer">
        <div class="headline">
          <h3>Welcome to Koding!</h3>
          This short video will give you an overview of your new cloud-based development environment. Get ready to say goodbye to localhost!
        </div>
        {{> @getStartedButton }}
      </div>
    """

