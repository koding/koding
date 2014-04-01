class BusinessView extends KDView

  constructor:->
    super

    @signUpButton = new KDButtonView
      title       : "SIGN UP NOW"
      style       : "solid medium green"

    @learnMoreButton = new KDButtonView
      title       : "LEARN MORE"
      style       : "solid medium white thin"

    @contentSlider = window.a = new BusinessSliderView
      contents     :
        first      :
          title    : "Control your dev environment like a boss"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        second     :
          title    : "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        third      :
          title    : "Control your dev environment like a boss"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        fourth     :
          title    : "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"


  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <article>
            <h2>Koding for Business</h2>
            <p>
              Ruby. Python. PHP. doesn’t matter. No setup,<br>
              just working VMs ready to roll. Watch a <em>quick video</em><br>
              to get the idea.
            </p>
            {{> @signUpButton}}
            {{> @learnMoreButton}}
          </article>
          <figure>
          </figure>
        </div>
      </section>

      <section class="features">
        <div class="inner-container clearfix">
          <div class="appstore feature">
            <h3>APPSTORE</h3>
            <p>Koding apps to speed up your noob processes<p>
          </div>
          <div class="teamwork feature">
            <h3>TEAMWORK</h3>
            <p>Collaborative development environment for your pleasure<p>
          </div>
          <div class="social feature">
            <h3>SOCIAL</h3>
            <p>Ask the masters of code, help out the poor noob.<p>
          </div>
        </div>
      </section>

      <section class="content-slider">
        <div class="inner-container">
          {{> @contentSlider}}
        </div>
      </section>

      <section class="pricing">
        <div class="inner-container">
          <h3 class="general-title">Single developer or a team, doesn’t really matter</h3>
          <h4 class="general-subtitle">Super-scalable pricing for your scalable projects</h4>
        </div>
      </section>

      <section class="insights">
        <div class="inner-container">

        </div>
      </section>

      <section class="customers">
        <div class="inner-container">

        </div>
      </section>

      <footer>
      </footer>
    """

class BusinessSliderSlideView extends KDView
  constructor : (options = {}) ->
    options.cssClass = KD.utils.curry "slide passive", options.cssClass
    options.content ?= {}

    super options

    @status = ""

    content = @getOption "content"

    @addSubView @title    = new KDCustomHTMLView
      tagName : "h3"
      cssClass: "general-title"
      partial : content.title

    @addSubView @subTitle = new KDCustomHTMLView
      tagName : "h4"
      cssClass: "general-subtitle"
      partial : content.subTitle

    @addSubView @image    = new KDCustomHTMLView
      tagName    : "img"
      attributes :
        src      : content.imgUrl
        alt      : content.title

  setActive : ->
    @unsetClass "passive"
    @setClass   "active"

  setPassive :->
    @unsetClass "active"
    @setClass   "passive"


class BusinessSliderView extends KDView
  constructor : (options = {}) ->
    options.cssClass   = KD.utils.curry "slider-wrapper", options.cssClass
    options.contents  ?= {}

    super options

    @slides  = []
    @navDots = []

    @createSlider()

  createSlider : ->
    for name, content of @getOption "contents"
      @addSubView slide =  new BusinessSliderSlideView
        cssClass : content.name
        content  : content

      @slides.push slide

    @prepareDots()
    @goTo 0

  prepareDots : ->
    @addSubView @dotsContainer = new KDCustomHTMLView
      tagName     : "nav"

    for slide in @slides
      @dotsContainer.addSubView dot = new KDView
        cssClass  : "dot"
        delegate  : @
        click     : ->
          index   = @getDelegate().navDots.indexOf this
          @getDelegate().goTo index

      @navDots.push dot

  goTo : (index) ->
    targetSlide   = @slides[index]
    currentsIndex = @slides.indexOf @activeSlide

    return if @activeSlide is targetSlide

    targetSlide.setActive()
    @activeSlide?.setPassive()

    @navDots[index].setClass "active"
    @navDots[currentsIndex].unsetClass "active" if currentsIndex > -1

    @activeSlide = targetSlide


