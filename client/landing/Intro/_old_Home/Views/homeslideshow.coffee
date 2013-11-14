class HomeSlideShow extends KDView

  slideData = [
      bg      : "/images/bg/blurred/1.jpg"
      title   : "<p><span>A new way for</span><br><span>developers to work!</span></p>"
    ]

  constructor:(options = {}, data)->

    data                  or= slideData
    options.tagName       or= "section"
    options.rotate         ?= yes
    options.rotationDelay or= 8000
    options.keydown         =
      left                  : => @interacted = yes; @slideTo "prev"
      right                 : => @interacted = yes; @slideTo "next"

    super options, data

    @slides     = []
    @pos        = 0
    @interacted = no
    @repeater   = null

  viewAppended:->

    @wrapper = new KDView
      cssClass   : 'clearfix'
      tagName    : 'ul'

    slide = slideData.first
    @wrapper.addSubView slide = new KDCustomHTMLView
      tagName    : 'li'
      partial    : slide.title
      attributes :
        style    : "background-image: url('#{slide.bg}'); width: #{100/@getData().length}%"

    @$().html ""

    @wrapper.on "viewAppended", @bound "_windowDidResize"
    KD.getSingleton('mainView').on "transitionend", @bound "_windowDidResize"

    @addSubView @wrapper

