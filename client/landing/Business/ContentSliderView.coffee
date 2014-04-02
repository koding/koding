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
