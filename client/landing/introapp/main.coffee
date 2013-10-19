class IntroPage extends KDSlidePageView

  constructor:(options={}, data)->
    super options, data

  pistachio:->
    content = @getOption 'content'
    return content if content

    """
      <div class="slider-page">
        <div class="wrapper">
          <figure><img src="/images/homeslide/#{@getData().slideImage}"></figure>
          <h3><i></i> {{ #(slogan) }}</h3>
          {{ #(subSlogan) }}
        </div>
      </div>
    """

class EntryPage extends KDSlidePageView

  constructor:->
    super cssClass : 'entryPage'

  viewAppended:->

    @addSubView new KDCustomHTMLView
      partial   : "A new way for developers to work"
      cssClass  : "slogan"

    @addSubView new KDCustomHTMLView
      partial   : "Software development has finally evolved,<br> It's now social, in the browser and free!"
      cssClass  : "sub-slogan"

    buttons = new KDCustomHTMLView cssClass : 'buttons'
    buttons.addSubView emailSignupButton  = new KDButtonView
      cssClass  : "email"
      partial   : "<i></i>Sign up <span>with email</span>"
      callback  : -> KD.getSingleton('router').handleRoute '/Register'

    buttons.addSubView gitHubSignupButton = new KDButtonView
      cssClass  : "github"
      partial   : "<i></i>Sign up <span>with gitHub</span>"
      callback  : -> KD.getSingleton("oauthController").openPopup "github"

    @addSubView buttons

class IntroView extends JView

  constructor:(options={}, data)->
    options.cssClass = 'intro-view'
    super options, data

  destroyIntro:->
    @setClass 'out'
    @utils.wait '500', => @destroy()

  viewAppended:->

    @addSubView slider = new KDSlideShowView
      direction : 'topToBottom'
      # animation : 'rotate'

    slider.addPage new EntryPage

    slider.addPage new IntroPage {},
      slideImage : "you.jpg"
      slogan     : "Koding for <span>You</span>"
      subSlogan  : """
        <p>
          You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.
        </p>
        <p>
          You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.
        </p>
      """

    slider.addPage new IntroPage {},
      slideImage : "developers.jpg"
      slogan     : "Koding for <span>Developers</span>"
      subSlogan  : """
        <p>
          You can have an amazing VM that is better than your laptop.  It's connected to internet 100x faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
        </p>
        <p>
          It's free. Koding is your new localhost, in the cloud.
        </p>
      """

    slider.addSubPage new IntroPage {},
      slideImage : "developers.jpg"
      slogan     : "Koding for <span>Sinan</span>"
      subSlogan  : """
        <p>
          You can have an amazing VM that is better than your laptop.  It's connected to internet 100x faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
        </p>
        <p>
          It's free. Koding is your new localhost, in the cloud.
        </p>
      """

    slider.addPage new IntroPage {},
      slideImage : "education.jpg"
      slogan     : "Koding for <span>Education</span>"
      subSlogan  : """
        <p>
          Create a group where your students enjoy the resources you provide to them. Make it private or invite-only.  Let them share, collaborate and submit their assignments together.  It doesn't matter if you have ten students, or ten thousand.  Scale from just one to hundreds of computers.
        </p>
        <p>
          Koding is your new classroom.
        </p>
      """

    slider.addPage new IntroPage {},
      slideImage : "business.jpg"
      slogan     : "Koding for <span>Business</span>"
      subSlogan  : """
        <p>
          When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.
        </p>
        <p>
          Koding is your new workspace.
        </p>
      """

    slider.addPage new IntroPage {},
      slideImage : "business.jpg"
      slogan     : "Pricing"
      subSlogan  : """
        <p>
          When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.
        </p>
        <p>
          Koding is your new workspace.
        </p>
      """

    labels = ['Koding', 'You', 'Developers', 'Education', 'Business', 'Pricing']
    hash   = location.hash.replace /^\#/, ''
    target = if hash in labels then hash else 'Koding'

    @addSubView multipleChoice = new KDMultipleChoice
      title        : ""
      labels       : labels
      defaultValue : [target]
      multiple     : no
      cssClass     : 'bottom-menu'
      callback     : (state)=>
        slider.jump labels.indexOf state
        state = '' if state is 'Koding'
        history.replaceState {}, state, "/##{state}"

    slider.on 'CurrentPageChanged', (current)->

      multipleChoice.setValue labels[current.x], no

      if current.x > 0
        multipleChoice.setClass 'black'
        @utils.wait 500, ->
          $('#koding-logo').addClass    'black'
          $('#header-sign-in').addClass 'black'
      else
        $('#koding-logo').removeClass    'black'
        $('#header-sign-in').removeClass 'black'
        @utils.wait 500, ->
          multipleChoice.unsetClass 'black'

    @utils.wait 300, ->
      if target isnt 'Koding' then multipleChoice.setValue target

KD.introView = new IntroView
KD.introView.appendToDomBody()

KD.utils.defer -> KD.introView.setClass 'in'