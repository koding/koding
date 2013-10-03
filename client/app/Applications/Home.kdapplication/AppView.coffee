class HomeAppView extends JView

  constructor:(options = {}, data)->

    super options, data


    #Slider
    @slider       = new HomeSlider
      cssClass    : "home-slider"
      pages       :
        "You"       :
          cssClass  : "slider-page"
          domId     : "you-page"
          pistachio :
            """
              <div class="wrapper">
                <figure></figure>
                <h3>
                  <i></i> Koding for <span>You</span>
                </h3>
                <p>
                  Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
                </p>
                <p>
                  Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
                </p>
              </div>
            """
        "Developers":
          cssClass  : "slider-page"
          domId     : "developers-page"
          pistachio :
            """
              <div class="wrapper">
                <figure></figure>
                <h3>
                  <i></i> Koding for <span>Developers</span>
                </h3>
                <p>
                  Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
                </p>
                <p>
                  Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
                </p>
              </div>
            """
        "Education" :
          cssClass  : "slider-page"
          domId     : "education-page"
          pistachio :
            """
              <div class="wrapper">
                <figure></figure>
                <h3>
                  <i></i> Koding for <span>Education</span>
                </h3>
                <p>
                  Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
                </p>
                <p>
                  Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
                </p>
              </div>
            """
        "Business"  :
          cssClass  : "slider-page"
          domId     : "business-page"
          pistachio :
            """
              <div class="wrapper">
                <figure></figure>
                <h3>
                  <i></i> Koding for <span>Business</span>
                </h3>
                <p>
                  Donec ullamcorper nulla non metus auctor fringilla. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper.
                </p>
                <p>
                  Maecenas sed diam eget risus varius blandit sit amet non magna. Maecenas faucibus mollis interdum.
                </p>
              </div>
            """

  _windowDidResize:->
    @unsetClass "extra-wide wide medium narrow extra-narrow"
    w = @getWidth()
    @setClass if w > 1500    then ""
    else if 1000 < w < 1500  then "extra-wide"
    else if 800  < w < 1000  then "wide"
    else if 600  < w < 800   then "medium"
    else if 480  < w < 600   then "narrow"
    else "extra-narrow"

  viewAppended:->
    super

    # account = KD.whoami()

    # @addSubView @featuredActivities = new FeaturedActivitiesContainer
    # @addSubView @footer = new KDCustomHTMLView tagName : 'footer'

    # @emit 'ready'

    # @utils.wait 500, => @_windowDidResize()
    # KD.getSingleton("contentPanel").on "transitionend", (event)=>
    #   event.stopPropagation()
    #   @_windowDidResize()  if $(event.target).is "#content-panel"

  pistachio:->
    """
    <section class="slider-section" id="slider-section">
      {{> @slider}}
    </section>
    <section class="pricing-section" id="pricing-section">
      <h3>Simple Pricing</h3>
      <h4>Try it and see if it's really as cool as we say</h4>
      <div class="price-boxes">
        <a href="#" class="free">
          <span>Your first VM</span>
          Free
        </a>
        <a href="#" class="paid">
          <span>Each additional VM</span>
          $3 / Month
        </a>
      </div>
      <div class="pricing-details">
        <span><strong>Always on*</strong> $4 / Month</span>
        <span><strong>Extra RAM</strong> $3 / GB / Month</span><br>
        <span><strong>Extra Disk Space</strong> $2 / GB / Month</span>
        <span><strong>FireWall / Network Rules</strong> $2 / GB / Month</span>
      </div>
      <span class="pricing-contact"><a href="#">Contact us</a> for Education and Business pricing</span>
    </section>
    <footer class="home-footer">
    </footer>
    """

class HomeSlider extends KDCustomHTMLView
  constructor:()->
    super
    @pages    = []
    @navItems = []

  createNav:->
    @addSubView @navContainer = new KDCustomHTMLView
      tagName       : "nav"
      cssClass      : "slider-nav"

    for page in @pages
      @navContainer.addSubView item = new SliderLink
        title       : page.getOption "navTitle"
        slider      : page.parent
      @navItems.push item
      @goToPage @navItems.first

  goToPage:(item)->
    for _item in @navItems
      _item.unsetClass "active" if item isnt _item
    item.setClass "active"

    index = @navItems.indexOf item

    if @activePage?
      @activePage.unsetClass "active"

    @pages[index].setClass "active"
    @activePage = @pages[index]


  createPages:->
    for title, page of @getOption "pages"
      @addSubView _page = new KDCustomHTMLView
        cssClass        : page.cssClass
        domId           : page.domId
        pistachio       : page.pistachio
        navTitle        : title

      @pages.push _page

  viewAppended:->
    @createPages()
    @createNav()
    @goToPage @navItems.first

class SliderLink extends CustomLinkView
  constructor:(options)->
    super

  click:->
    slider = @getOption "slider"
    slider.goToPage this








