class IntroPage extends KDSlidePageView

  constructor:(options={}, data)->
    super options, data

  pistachio:->
    content = @getOption 'content'
    return content if content

    time = new Date().getTime()

    """
      <div class="slider-page">
        <div class="slogan">{{ #(slogan) }}</div>
        <div class="wrapper">
          <figure>
            <img src="/images/homeslide/#{@getData().slideImage}?#{time}" />
          </figure>
          <div class="details">
            {{ #(subSlogan) }}
          </div>
        </div>
      </div>
    """

class EntryPage extends KDSlidePageView

  constructor:->
    super cssClass : 'entryPage'

  viewAppended:->

    @addSubView new KDCustomHTMLView
      cssClass  : "top-slogan"
      partial   : """
        A new way for developers to work
        <div>Software development has finally evolved,<br> It's now social, in the browser and free!</div>
      """

    buttons = new KDCustomHTMLView cssClass : 'buttons'
    buttons.addSubView emailSignupButton  = new KDButtonView
      cssClass  : "email"
      partial   : "<i></i>Sign up <span>with email</span>"
      callback  : -> KD.getSingleton('router').handleRoute '/Register'

    buttons.addSubView gitHubSignupButton = new KDButtonView
      cssClass  : "github"
      partial   : "<i></i>Sign up <span>with GitHub</span>"
      callback  : -> KD.getSingleton("oauthController").openPopup "github"

    @addSubView buttons

class IntroView extends JView

  constructor:(options={}, data)->
    options.cssClass = 'intro-view'
    options.bind     = 'scroll mousewheel wheel'
    super options, data

  setCurrentPage: (direction)->
    unless @_lock
      @_lock = yes
      @slider[direction]()
      @utils.wait 1200, => delete @_lock

  mouseWheel:(e)->
    oevent = e.originalEvent

    if oevent? and not @_lock

      deltaY = oevent.wheelDeltaY or -oevent.deltaY
      deltaX = oevent.wheelDeltaX or -oevent.deltaX

      if deltaY < -15 then @setCurrentPage 'nextPage'
      if deltaY >  15 then @setCurrentPage 'previousPage'
      if deltaX >  15 then @setCurrentPage 'previousSubPage'
      if deltaX < -15 then @setCurrentPage 'nextSubPage'

    KD.utils.stopDOMEvent e

  destroyIntro:->
    @setClass 'out'
    @utils.wait '500', => @destroy()

  viewAppended:->

    @addSubView @slider = new KDSlideShowView
      direction : 'topToBottom'
      # animation : 'rotate'

    @slider.addPage new EntryPage

    @slider.addPage new IntroPage {},
      slideImage : "you.svg"
      slogan     : "for <span>You</span>"
      subSlogan  : """
        <p>
          You have great ideas.  You want to meet brilliant minds, and bring those ideas to life.  You want to start simple.  Maybe soon you'll have a 10 person team, commanding 100s of servers.
        </p>
        <p>
          You want to learn Python, Java, C, Go, Nodejs, HTML, CSS or Javascript or any other. Community will help you along the way.
        </p>
      """

    @slider.addPage new IntroPage {},
      slideImage : "developers.svg"
      slogan     : "for <span>Developers</span>"
      subSlogan  : """
        <p>
          You will have an amazing virtual machine that is better than your laptop.  It's connected to the internet 100's of times faster.  You can share it with anyone you wish. Clone git repos.  Test and iterate on your code without breaking your setup.
        </p>
        <p>
          It's free. Koding is your new localhost, in the cloud.
        </p>
      """

    @slider.addPage new IntroPage {},
      slideImage : "education.svg"
      slogan     : "for <span>Education</span>"
      subSlogan  : """
        <p>
          Create a group where your students enjoy the resources you provide to them. Make it private or invite-only.  Let them share, collaborate and submit their assignments together.  It doesn't matter if you have ten students, or ten thousand.  Scale from just one to hundreds of computers.
        </p>
        <p>
          Koding is your new classroom.
        </p>
      """

    @slider.addPage new IntroPage {},
      slideImage : "business.svg"
      slogan     : "for <span>Business</span>"
      subSlogan  : """
        <p>
          When you hire someone, they can get up to speed in your development environment in 5 minutes—easily collaborating with others and contributing code.  All without sharing ssh keys or passwords.  Stop cc'ing your team; stop searching through old emails.
        </p>
        <p>
          Koding is your new workspace.
        </p>
      """

    @slider.addPage new IntroPage {},
      slideImage : "price.svg"
      slogan     : "Pricing"
      subSlogan  : """
        <p>
          You'll be able to buy more resources for your personal account or for accounts in your organization.
        </p>
        <p>
          Coming soon.
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
        @slider.jump labels.indexOf state
        state = '' if state is 'Koding'
        history.replaceState {}, state, "/##{state}"

    @slider.on 'CurrentPageChanged', (current)=>

      multipleChoice.setValue labels[current.x], no

      if current.x > 0
        @setClass 'ghost'
        multipleChoice.setClass 'black'
        @utils.wait 500, ->
          $('#main-header').addClass 'black'
      else
        $('#main-header').removeClass 'black'
        @unsetClass 'ghost'
        @utils.wait 500, ->
          multipleChoice.unsetClass 'black'

    @utils.wait 300, ->
      if target isnt 'Koding' then multipleChoice.setValue target

    $(window).on 'resize orientationchange', => @updateSize()
    @updateSize()

  updateSize:->
    # Poor man's font resizer ~ GG
    sizes = @slider.currentPage.getBounds()
    @slider.setCss
      fontSize : Math.max Math.min( (sizes.w + sizes.h) / 80, parseFloat 20 ), parseFloat 12

KD.introView = new IntroView
KD.introView.appendToDomBody()

KD.utils.defer -> KD.introView.setClass 'in'
