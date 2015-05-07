CustomLinkView = require './../core/customlinkview'
FooterView     = require './../home/footerview'
MainHeaderView = require './../core/mainheaderview'

module.exports = class FeaturesView extends KDView

  IMAGEPATH      = '/a/site.landing/images/features'
  TABS           = require './tabs'
  BOTTOMFEATURES = require './bottomfeatures'

  constructor:(options = {}, data)->

    super options, data

    @addSubView @header = new MainHeaderView
    @setPartial @partial()

    @handles = {}
    @prepareTabHandles()

    @addSubView @footer = new FooterView


  prepareTabHandles: ->

    for tabName, content of TABS
      { isDefault } = content
      tabPath = if isDefault then '' else "/#{tabName}"
      @handles[tabName] = handle = new CustomLinkView
        title           : tabName
        href            : "/Features#{tabPath}"

      @addSubView handle, '.tab-handles'


  selectTab : (tabName) ->

    if not tabName
      for name, content of TABS
        if content.isDefault
          tabName = name
          break

    for name, handle of @handles
      handle.unsetClass 'active'

    @handles[tabName]?.setClass 'active'

    {text, image}   = TABS[tabName]

    tabView         = new KDCustomHTMLView
      tagName       : 'article'
      cssClass      : "tab-#{tabName.toLowerCase()} tab-enter clearfix"

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-text'
      partial       : text

    tabView.addSubView new KDCustomHTMLView
      cssClass      : 'tab-image'
      tagName       : 'img'
      attributes    :
        'src'       : "#{IMAGEPATH}/#{image}"

    tabView.addSubView new KDCustomHTMLView cssClass: 'clearfix'

    tabView.addSubView @createBottomFeatures tabName

    if @currentTab
      leaveFn = =>
        @currentTab.destroy()
        @addSubView @currentTab = tabView, '.tab-contents'

      domElement = @currentTab.getDomElement()[0]

      domElement.addEventListener 'webkitAnimationEnd', leaveFn, false
      domElement.addEventListener 'animationend',       leaveFn, false

      @currentTab.setClass 'tab-leave'

    else
      @addSubView @currentTab = tabView, '.tab-contents'


  createBottomFeatures: (tabName) ->
    bottomFeatures = new KDCustomHTMLView
      cssClass     : 'bottom-features clearfix'

    for title, content of BOTTOMFEATURES[tabName]
      do (title, content) =>
        view = new KDCustomHTMLView
          cssClass    : 'feature-item'
          partial     : "
            <h5 class='#{content.iconClass}'><cite></cite>#{title}</h5>
            <p>#{content.text}</p>
          "
        bottomFeatures.addSubView view

    return bottomFeatures


  partial: ->

    """
    <section class='feature-tabs'>
      <nav class='tab-handles'></nav>
      <div class='tab-contents'></div>
    </section>
    """


