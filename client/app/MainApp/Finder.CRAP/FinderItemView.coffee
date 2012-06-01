class FinderItemView extends KDTreeItemView
  constructor:->
    super

    fileData = @getData()

    @loader = new KDLoaderView
      size          : 
        width       : 16
      loaderOptions :
        # color       : @utils.getRandomHex()
        color       : "#222222"
        shape       : "spiral"
        diameter    : 16    
        density     : 30
        range       : 0.4
        speed       : 1.5
        FPS         : 24

    @icon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon"

    fileData.on 'list.start',  => @showLoader()
    fileData.on 'list.finish', => @hideLoader()
    fileData.on 'list.failed', => @hideLoader()

  decorateItem:->
    extension = __utils.getFileExtension @getData().name
    if extension
      fileType = __utils.getFileType extension
      @icon.$().attr "class", "icon #{extension} #{fileType}"

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    @hideLoader()
    @decorateItem()
    # @checkTitleSize()
  
  showLoader:->
    @icon.hide()
    @loader.show()
  
  hideLoader:->  
    @icon.show()
    @loader.hide()
  
  pistachio:->
    """
     <div class='finder-item clearfix'>
       {{> @loader}}
       {{> @icon}}
       {span.title{ #(name)}}
     </div>
     <span class='chevron-arrow'></span>
    """

  contextMenu:(event)->
    if event.pageX is 0 and event.pageY is 0
      chevronOffset = @$('.chevron-arrow').offset()
      event.pageX = chevronOffset.left - 4
      event.pageY = chevronOffset.top + 18
    no

  click:(event)->
    super
    $target = $(event.target)
    if $target.is('.chevron-arrow')
      event.type = 'contextmenu'
      @handleEvent event
      event.type = 'click'
      no
      
    # log "FIX RENAMING BEHAVIOR"
    # else if $target.is('.title')
    #   clearTimeout @_canRenameTimerStart
    #   clearTimeout @_canRenameTimerStop
    #   
    #   if @_canRename
    #     @performRename()
    #     @propagateEvent KDEventType : 'ContextMenuFunction', globalEvent : yes, {functionName:'rename', contextMenuDelegate:@}
    #     @_canRename = no
    #   else    
    #     @_canRenameTimerStart = setTimeout =>
    #       @_canRename = yes
    #     ,500
    #   
    #     @_canRenameTimerStop = setTimeout =>
    #       @_canRename = no
    #     ,1500
      

    else yes

  classContextMenuItems: ->
    [
      # { type : 'divider',                   id : 91,    parentId : null } 
      # {title  : 'Show/Hide hidden files',   id : 92,    parentId : null,  action : 'showHideHidden' }
      # {type : 'divider',  id : 103, parentId : null}
      { title : 'Attach Mount...',              id : 1104,  parentId : null, disabledForBeta : yes }
      { title : 'Loading available mounts...',  id : 1105,  parentId : 1104,  type : "addMount" }
      { type  : 'divider',                      id : 1200,  parentId : null }
      { title : '⌘ Keyboard Shortcuts',         id : 1201,  parentId : null, action : "showKeyboardHelper" }
    ]

  performRemove:()=>
    @undim()
    @setClass "being-inline-edited being-deleted"
    @$('.finder-item').hide()
    
  performSetPermissions: (permissions, recursive) =>
    @propagateEvent KDEventType : 'permissionsChange', globalEvent : yes, {permissions, recursive}
  
  fetchPermissions: (callback)=>
    @propagateEvent KDEventType : 'permissionsFetch', callback
    
  performRename: () =>

    # FIX
    # BUGGY Sometimes refresh the page
    # Form is necessary to have the default behavior
    
    
    @setClass "being-inline-edited"
       
  dim: ->
    super
    @propagateEvent KDEventType : 'highlightRemoved', globalEvent : yes
    
  removeHighlight: ->
    super
    @propagateEvent KDEventType : 'highlightRemoved', globalEvent : yes
    # clearTimeout @_changeNameByClickTimeout
    # @_canChangeNameByClick = no
    
    #setting timeout to allow change title in couple of moments
    # clearTimeout @_changeNameByClickTimeout
    # @_changeNameByClickTimeout = setTimeout =>
    #   @_canChangeNameByClick = yes
    # , 400
  
  pasteboard:()->
    #FIXME, this doesn't seem logical here...
    if @ not in @getDragDelegate().selectedItems
      @getDragDelegate().makeItemSelected @

    items = for item in @getDragDelegate().selectedItems
      item.getData()

  isDraggable:()->
    return @draggingEnabled ? yes #make yes for class draggability

  isDroppable:()->
    return @droppingEnabled ? yes #make yes for class droppability

  dragOptions:()->
    revert            : "invalid"
    revertDuration    : 300
    appendTo          : "body"
    containment       : "body"
    refreshPositions  : true
    # cursor            : "move"
    # delay             : 1
    cursorAt          :
      left            : -10
      top             : 5
    helper            : ()=>
        container = $ '<div />', class : 'finder-drag-container clearfix'
        setTimeout => #draw items after drag is started
          itemsCount = @getDragDelegate().selectedItems.length
          
          if itemsCount > 5
            container.append $item = $ "<div class='finder-item multiple-items drag-helper'>
                <span class='title'> #{itemsCount} items are being moved...</span>
              </div>"
            $item.width $item.find("span.title").outerWidth() + 12
            
          else
            for item in @getDragDelegate().selectedItems
              container.append $item = $ "<div class='finder-item drag-helper #{item.getData().type}-item'>
                  <span class='icon'></span>
                  <span class='title'>#{item.getData().name}</span>
                </div>"
              $item.width $item.find("span.icon").outerWidth() + $item.find("span.title").outerWidth() + 12
        , 100
        
        @getDragDelegate()._currentDragHelper = container
        container
    opacity:        1
    scroll:         no
    zIndex:         2

  dropOptions:()->
    tolerance: 'pointer'
    
  drag:(event,ui)=>
    {w, h, x, y} = @getDelegate().parent.getBounds() #finder parent bounds
    {left, top} = ui.offset
    
    if x + w > left > x and h > top > x
      if h > top > h - 100
        @getDelegate().scrollDown()
      else if x + 100 > top > x
        log 'scroll up'
        @getDelegate().scrollUp()
      else
        @getDelegate().stopScroll()
    else
      @getDelegate().stopScroll()
    # log 'drag in process', ui, event, @getDelegate().getBounds(), @getDelegate().parent, @getDelegate().parent.getBounds()
    switch event.metaKey
      when yes then @getDomElement().data("operation","copyTo")
      else @getDomElement().data("operation","moveTo")
      

  dragStop:(event,ui)=>
    @getDelegate().stopScroll()
    @getDomElement().removeData('operation')
    @getDelegate().removeAllDropHelpers()
    for item in @getDragDelegate().itemsOrdered
      item.$().css cursor: 'default'

  dropAccept:(item)=>
    if @getDropDelegate()    
      accept = if ((controller = @getDropDelegate()).checkPermissions operation:item.data("operation"), target:@getData(), source:item.data('KDPasteboard'))
        yes unless (controller.nearestFolder item.data('KDPasteboard')) is controller.nearestFolder @getData()
        
      if accept
        @$().css cursor: if item.data("operation") is 'copyTo' then 'copy' else 'default'
      else
        @$().css cursor: 'no-drop'
        
      accept

  dropOver:(event,ui)=>
    ui.draggable.data("target", @getDropDelegate().nearestFolder @.getData())
    @getDelegate().makeItemDropTarget ui.draggable.data("target")
    clearTimeout @__timerToOpen
    if @getData().type is 'folder' and not @expanded
      @__timerToOpen = setTimeout =>
        @blink =>
          @getDropDelegate().expandFolder @
      , 500
    
  blink: (cb) ->
    @setClass 'selected'
    unselect = (cb) =>
      setTimeout =>
        @unsetClass 'selected'
        cb?()
      , 100
      
    select = (cb) =>
      setTimeout =>
        @setClass 'selected'
        cb?()
      , 50
      
    unselect ->
      select ->
        unselect ->
          cb()

  dropOut:(event,ui)=>
    clearTimeout @__timerToOpen
    @getDelegate().removeAllDropHelpers()
    # @getDelegate().nearestFolder(@.getData()).$().find('div.drop-helper').remove()
    # seems out and over are not always called in suquence, fast moving of the mouse leads to out being called after over...
      # @getDelegate().removeAllDropHelpers()
      # log "out"

  jQueryDrop:(event,ui)=>
    return log 'cancelled drop' if event.originalEvent.cancelDrop
      
    #switch copy vs move
    finder            = @getDelegate()
    finderController  = @getDropDelegate()
    dragTo            = ui.draggable.data("target").getData()
    operation         = ui.draggable.data "operation"
    items             = ui.draggable.data('KDPasteboard')
    
    finderController[operation]?(@, {destination:dragTo, items})

    super
    
  destroy: ->
    @emit 'destroy'
    super

  # checkTitleSize: ->
  #   return
  #   unless @$title
  #     @$title       = @$('.title:first')
  #   
  #   width           = @getDelegate().getTrickyWidth()
  #   calculator      = @getDelegate().getCalculator()
  #   calculatorTitle = calculator.title
  #   
  #   cropTo = (width, crop = 0) =>
  #     checkNewTitle = @getCroppedTitle crop
  #     titleCloneWidth = calculator.width checkNewTitle
  #     
  #     return if titleCloneWidth is 0
  #   
  #     if titleCloneWidth < width or @getData().title.length - crop < 5
  #       @$title.html checkNewTitle
  #     else
  #       cropTo width, crop + 1
  #       
  #   # log 'depth', @getData().path.split('/').length, @getData().path
  #   cropTo width - (25 + (@getData().path.split('/').length - 1) * 15)
        
  # getCroppedTitle: (len) ->
  #   title = @getData().title
  #   if len is 0
  #     title
  #   else
  #     currentLength = title.length
  #     newTitle = ''
  #     newTitle += title.substr 0, (currentLength / 2) - (len/2)
  #     newTitle += '...'
  #     newTitle += title.substr (currentLength / 2) + (len/2), currentLength

  # showHide:->
  #   if @$().hasClass 'hidden' 
  #     @unsetClass 'hidden'
  #     localStorage.setItem 'hiddenFiles', 'visible'
  #   else if @$().hasClass 'hideable'
  #     @setClass 'hidden'
  #     localStorage.setItem 'hiddenFiles', 'hidden'
