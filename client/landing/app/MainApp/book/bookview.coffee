###
  todo
    - page switching ui
    - develop fake button items and styling
    - flip pages by clicking left or right half of the pages
###

class BookView extends JView

  @lastIndex = 0
  cached = []
  cachePage = (index)->
    return if not __bookPages[index] or cached[index]
    page = new BookPage {}, __bookPages[index]
    KDView.appendToDOMBody page
    __utils.wait ->
      cached[index] = yes
      page.destroy()

  constructor: (options = {},data) ->

    options.domId    = "instruction-book"
    options.cssClass = "book"

    super options, data

    @currentIndex = 0

    @right = new KDView
      cssClass    : "right-page right-overflow"
      click       : -> @setClass "flipped"

    @left = new KDView
      cssClass    : "left-page fl"

    @pagerWrapper = new KDCustomHTMLView
      cssClass : "controls"

    @pagerWrapper.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "◀"
      click     : (pubInst, event)=> @fillPrevPage()
      tooltip   :
        title   : "⌘ Left Arrow"
        gravity : "sw"

    @pagerWrapper.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "▶"
      click     : (pubInst, event)=> @fillNextPage()
      tooltip   :
        title   : "⌘ Right Arrow"
        gravity : "se"

    @putOverlay
      cssClass    : ""
      isRemovable : yes
      animated    : yes

    @once "OverlayAdded", => @$overlay.css zIndex : 999
    @once "OverlayWillBeRemoved", => @unsetClass "in"
    @once "OverlayRemoved", @destroy.bind @

    @setKeyView()
    cachePage(0)

  pistachio:->

    """
    {{> @left}}
    {{> @right}}
    {{> @pagerWrapper}}
    """

  click:(event)->

    @setKeyView()
    # if event.pageX < 400 then @fillPrevPage() else @fillNextPage()


  keyDown:(event)->

    switch event.which
      when 37 then do @fillPrevPage
      when 39 then do @fillNextPage
      when 27
        @unsetClass "in"
        @utils.wait 600, => @destroy()

  getPage:(index = 0)->

    @currentIndex = index

    page = new BookPage
      delegate : @
    , __bookPages[index]

    return page

  fillPrevPage:->

    return if @currentIndex - 1 < 0
    @fillPage @currentIndex - 1

  fillNextPage:->

    return if __bookPages.length is @currentIndex + 1
    @fillPage @currentIndex + 1

  fillPage:(index)->

    cachePage index+1
    index ?= BookView.lastIndex
    BookView.lastIndex = index
    page = @getPage index

    if @$().hasClass "in"
      @right.setClass "out"
      @utils.wait 300, =>
        @right.destroySubViews()
        @right.addSubView page
        @right.unsetClass "out"
    else
      @right.destroySubViews()
      @right.addSubView page
      @right.unsetClass "out"
      @utils.wait 400, =>
        @setClass "in"

