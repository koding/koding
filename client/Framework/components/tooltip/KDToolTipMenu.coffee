class KDToolTipMenu extends KDView
  constructor:(options,data)->
    options = options ? {}
    # options.parent = "body"
    options.cssClass = "kdtooltipmenu"
    options.tipPosition = options.tipPosition ? "top"
    options.cssClass += " tip-at-#{options.tipPosition}"
    super options,data
    @handleEvent type : "destroySiblings"
    @positionTo = options.positionTo ? @getDelegate()
    @createTrees data
    
    @listenTo
      KDEventTypes:[
        {className : "KDView",eventType: "click"}
        {className : "KDView",eventType: "tooltipmenu"}
        {className : "KDView",eventType: "destroySiblings"}
      ]
      callback:@aClick
    (@getSingleton "windowController").setKeyView @ #keyboard navigation of tooltip menu

  createTrees:(data)->
    for tree in data
      @addSubView toolTipTree = new KDToolTipMenuTreeView
        delegate : @
      new KDToolTipMenuTreeViewController view : toolTipTree, tree
      @addSubView new KDToolTipMenuListItemSeparator()
    @positionToolTipMenu()

  aClick:(instance,event)->
    (@getSingleton "windowController").scrollingEnabled = no
    unless event is @getOptions().event #don't destroy when this tooltip menu click gets propagated
      @destroy()
      (@getSingleton "windowController").scrollingEnabled = yes

  positionToolTipMenu:()->
    @offset = @positionTo.$().offset()
    @revertPosition() unless @isToolTipInViewport()
    tipPos  = @getOptions().tipPosition
    width   = @positionTo.getWidth()
    height  = @getHeight()
    if tipPos is "top"
      @$().css
        width     : width
        top       : @offset.top + @positionTo.getHeight()
        left      : @offset.left
    else
      @$().css
        width     : width
        top       : @offset.top - height - 7
        left      : @offset.left
  
  keyDown:(e)->
    switch e.which
      when 27
        (@getSingleton "windowController").setKeyView @getDelegate().getDelegate()
        @destroy() #esc

  viewAppended:()->
    @setPartial "<span class='tip'/>"
    @setPartial "<h2 class='kdtooltipheader'>#{@getOptions().title}</h2>"

  isToolTipInViewport:()->
    # return yes if it stays in viewport no if not
    winHeight = $(window).height()
    height = @getHeight()
    if winHeight - (height + @offset.top) - 30 > 0 then yes else no

  revertPosition:()->
    tipPos = @getOptions().tipPosition
    if tipPos is "top"
      @unsetClass "tip-at-top"
      @setClass "tip-at-bottom"
      @options.tipPosition = "bottom"
    else
      @unsetClass "tip-at-bottom"
      @setClass "tip-at-top"
      @options.tipPosition = "bottom"

  # keyDown:(event)->
  #   switch event.which
  #     when 37 then @goLeft()
  #     when 38 then @goUp()
  #     when 39 then @goRight()
  #     when 40 then @goDown()
  #   no

class KDToolTipMenuTreeViewController extends KDTreeViewController
  constructor:(options,data)->
    options = options ? {}
    options.subItemClass ?= KDToolTipMenuTreeItem
    super options, data

  itemClass:(options,data)->
    itemInstance = super
    
    @listenTo 
      KDEventTypes        : [ eventType : 'click' ]
      listenedToInstance  : itemInstance
      callback            : @itemClicked
  
  itemClicked:(item, event)=>
    toolTipMenu = @getView().getDelegate()
    delegate = toolTipMenu.getDelegate()
    if delegate["perform#{@getData().function.capitalize()}"]()?
      delegate["perform#{@getData().function.capitalize()}"]()

class KDToolTipMenuTreeView extends KDTreeView
  constructor:(options,data)->
    options = options ? {} 
    options.cssClass = "kdtooltipmenutreeview"
    super options,data
    @setHeight "auto"

  setDomElement:()->
    @domElement = $ "<div id = '#{@id}' class='kdview #{@getOptions().cssClass}'></div>"

class KDToolTipMenuTreeItem extends KDTreeItemView
  constructor:(options,data)->
    options = options ? {}
    super options,data

  partial:(data)->
    partial = $ "<div class='tooltip-menu-item'>
          <span class='iconic'></span>
          <a href='/#/#{data.type}/add' class='add-new-item' title='Add new #{data.type}'>#{data.title}</a>
      </div>"
  
  click:(event)->
    no

class KDToolTipMenuListItemSeparator extends KDView
  constructor:(options,data)->
    super options,data
    @setClass "tooltip-menu-item-separator"


# class KDToolTipView extends KDView
#   partial :->
#     """
#     <div class='gtooltip propagateTooltipDestroy'>
#       <cite class='propagateTooltipDestroy'>Status Update</cite>
#       <div class='tipwrap'>
#         <span class='arrow bottom'></span>
#         <span class='arrow left'></span>
#         <span class='arrow top'></span>
#         <span class='arrow right'></span>
#       </div>
#     </div>
#     """
