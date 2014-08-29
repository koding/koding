class IDE.OnboardingModalContent extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'content-container'

    super options, data

    @createSubViews()


  createSubViews: ->

    @headline = new KDCustomHTMLView
      cssClass : 'headline'
      partial  : 'Welcome to your awesome dev environment'

    @getStartedButton = new KDButtonView
      title    : 'Get Started'
      cssClass : 'get-started solid green medium'
      callback : @bound 'getStarted'


  getStarted: -> @emit 'GetStartedButtonClicked'


  pistachio: ->
    """
    <div class="top-container">
      <div class="video-placeholder"></div>
    </div>
    <div class="footer">
      {{> @headline}}
      {{> @getStartedButton }}
    </div>
    """

