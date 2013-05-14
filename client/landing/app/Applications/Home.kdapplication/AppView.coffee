class HomeAppView extends KDView

  constructor:(options = {}, data)->

    options.domId    = "home-header"
    options.cssClass = "screenshots"

    super options, data

  viewAppended:->

    account = KD.whoami()
    # @addSubView @header = new WelcomeHeader
    #   domId     : "home-welcome-header"
    #   type      : "big"
    #   title     : if KD.isLoggedIn() then\
    #     "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
    #     "Welcome to the Koding Public Beta!<br>"
    #   subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    @addSubView @slideShow = new HomeSlideShow
      domId   : "home-slideshow"

    @addSubView @counterBar = new CounterGroupView
      domId    : "home-counter-bar"
      tagName  : "section"
    ,
      "Members"          : count : 0
      "Virtual Machines" : count : 0
      "Lines of Code"    : count : 0
      "Groups"           : count : 0
      "Topics"           : count : 0

    @counterBar.counters.Members.ready =>
      KD.remote.api.JAccount.count "", (err, count)=>
        @counterBar.counters.Members.update count or 0

    @counterBar.counters["Virtual Machines"].ready =>
      @getSingleton("vmController").getTotalVMCount (err, count)=>
        @counterBar.counters["Virtual Machines"].update count or 0

    @counterBar.counters["Lines of Code"].ready =>
      @getSingleton("vmController").getTotalLoC (err, count)=>
        @counterBar.counters["Lines of Code"].update count or 0

    @counterBar.counters.Groups.ready =>
      KD.remote.api.JGroup.count "", (err, count)=>
        @counterBar.counters.Groups.update count or 0

    @counterBar.counters.Topics.ready =>
      KD.remote.api.JTag.count "", (err, count)=>
        @counterBar.counters.Topics.update count or 0

    @addSubView @homeLoginBar = new HomeLoginBar
      domId    : "home-login-bar"

  # OLD HOME PISTACHIO
  # left here for reference - SY

  # pistachio:->

  #   """
  #   <div class="kdview video-wrapper">
  #     <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="89.13%"
  #     height="76.60%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen=""
  #     allowfullscreen="">
  #     </iframe>
  #   </div>
  #   <div class="home-links">
  #     <p class="bigLink">{{> @request}}</p>
  #     <p class="bigLink">{{> @register}}</p>
  #     <p class="bigLink">{{> @login}}</p>
  #     <p class="bigLink">{{> @learn}}</p>
  #   </div>
  #   <section>
  #     <hr id="home-reviews">
  #     <div class="reviews">
  #       <p>A new way for developers to work</p>
  #       <span>We said.</span>
  #       <p>Wow! Cool - good luck!</p>
  #       <span>Someone we talked to the other day...</span>
  #       <p>I don't get it... What is it, again?</p>
  #       <span>Same dude.</span>
  #       <p>Real software development in the browser...</p>
  #       <span>Us again.</span>
  #       <p>with a real VM and a real Terminal?</p>
  #       <span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span>
  #     </div>
  #     <hr />
  #     <div id="home-screenshots" class="screenshots">
  #       <div class="kdview">
  #         {{> @leftArrow}}
  #         {{> @rightArrow}}
  #         {{> @slideShow}}
  #       </div>
  #     </div>
  #     <hr />
  #     <footer id="copy-footer" class="copy">
  #       ©#{(new Date).getFullYear()} Koding, Inc. 358 Brannan Street, San Francisco, CA 94107
  #     </footer>

  #   </section>
  #   """




