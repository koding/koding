class JContextMenu extends KDView

  constructor:(options = {},data)->

    options.cssClass        = @utils.curryCssClass "jcontextmenu", options.cssClass
    options.menuWidth     or= 172
    options.offset        or= {}
    options.offset.left   or= 0
    options.offset.top    or= 0
    options.arrow          ?= no

    super options, data

    o = @getOptions()

    @getSingleton("windowController").addLayer @

    @on 'ReceivedClickElsewhere', => @destroy()

    if data
      @treeController = new JContextMenuTreeViewController
        type              : o.type
        view              : o.view
        delegate          : @
        treeItemClass     : o.treeItemClass
        listViewClass     : o.listViewClass
        itemChildClass    : o.itemChildClass
        itemChildOptions  : o.itemChildOptions
        addListsCollapsed : o.addListsCollapsed
        putDepthInfo      : o.putDepthInfo
        lazyLoad          : o.lazyLoad ? no
      , data
      @addSubView @treeController.getView()
      @treeController.getView().on 'ReceivedClickElsewhere', => @destroy()

    if options.arrow
      @on "viewAppended", @bound "addArrow"

    KDView.appendToDOMBody @

  childAppended:->

    @positionContextMenu()
    super

  addArrow:->

    o = @getOptions().arrow
    o.placement or= "top"
    o.margin     ?= 0

    @arrow = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "arrow #{o.placement}"

    @arrow.$().css switch o.placement
      when "top"
        rule = top : -7
        if o.margin > 0 then rule.left = o.margin else rule.right = -(o.margin)
        rule
      when "bottom"
        rule = bottom : 0
        if o.margin > 0 then rule.left = o.margin else rule.right = -(o.margin)
        rule
      when "right"
        rule = right : -7
        if o.margin > 0 then rule.top = o.margin else rule.bottom = -(o.margin)
        rule
      when "left"
        rule = left : -11
        if o.margin > 0 then rule.top = o.margin else rule.bottom = -(o.margin)
        rule
      else {}

    @addSubView @arrow

  positionContextMenu:()->
    options     = @getOptions()
    event       = options.event or {}
    mainView    = @getSingleton 'mainView'

    mainHeight  = mainView.getHeight()
    mainWidth   = mainView.getWidth()

    menuHeight  = @getHeight()
    menuWidth   = @getWidth()

    top         = (options.y or event.pageY or 0) + options.offset.top
    left        = (options.x or event.pageX or 0) + options.offset.left

    if top + menuHeight > mainHeight
      top  = mainHeight - menuHeight + options.offset.top

    if left + menuWidth > mainWidth
      left  = mainWidth - menuWidth + options.offset.left

    @getDomElement().css
      width     : "#{options.menuWidth}px"
      top       : top
      left      : left