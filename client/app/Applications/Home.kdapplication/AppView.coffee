class HomeAppView extends JView

  constructor:->

    super

    @setClass "screenshots"

    account = KD.whoami()

    @header = new WelcomeHeader
      type      : "big"
      title     : if KD.isLoggedIn() then\
        "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
        "Welcome to the Koding Public Beta!<br>"
      subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    @slideShow = new HomeSlideShow
      tagName : "section"

    @leftArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow left"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideShow.slideTo "prev"

    @rightArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow right"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideShow.slideTo "next"

    @homeLoginBar = new HomeLoginBar

    @slideShow.on "FirstSlideShown", =>
      @rightArrow.$().css right : 0
      @leftArrow.$().css  left  : -40

    @slideShow.on "LastSlideShown", =>
      @leftArrow.$().css  left  : 0
      @rightArrow.$().css right : -40

    @slideShow.on "OtherSlideShown", =>
      @leftArrow.$().css  left  : ""
      @rightArrow.$().css right : ""

  pistachio:->

    """
    {{> @header}}
    {{> @leftArrow}}
    {{> @rightArrow}}
    {{> @slideShow}}
    {{> @homeLoginBar}}
    """

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




