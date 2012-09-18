###
  todo
    - page switching ui
    - develop fake button items and styling
    - flip pages by clicking left or right half of the pages
###

class BookView extends JView

  @lastIndex = 0

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

    @putOverlay
      cssClass    : ""
      isRemovable : yes
      animated    : yes

    @once "OverlayAdded", => @$overlay.css zIndex : 999
    @once "OverlayWillBeRemoved", => @unsetClass "in"
    @once "OverlayRemoved", @destroy.bind @

    @setKeyView()

  pistachio:->

    """
    {{> @left}}
    {{> @right}}
    """

  click:-> @setKeyView()

  keyDown:(event)->

    switch event.which
      when 37 then do @fillPrevPage
      when 39 then do @fillNextPage

  getPage:(index = 0)->

    @currentIndex = index

    page = new BookPage
      delegate : @
    , __bookPages[index]

    return page

  fillPrevPage:->

    return if @currentIndex - 1 < 0
    BookView.lastIndex = @currentIndex - 1
    @fillPage @currentIndex - 1

  fillNextPage:->

    return if __bookPages.length is @currentIndex + 1
    BookView.lastIndex = @currentIndex + 1
    @fillPage @currentIndex + 1

  fillPage:(index)->

    index or= BookView.lastIndex
    page = @getPage index
    @right.setClass "out"
    @utils.wait 300, =>
      @setClass "in"
      @right.destroySubViews()
      @right.addSubView page
      @right.unsetClass "out"
