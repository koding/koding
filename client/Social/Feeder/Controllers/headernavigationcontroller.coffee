class HeaderNavigationController extends KDController

  constructor:(options, data)->

    super

    mainView       = @getDelegate()
    {items, title} = @getData()
    @currentItem   = items.first

    itemsObj = {}
    items.forEach (item)=>
      itemsObj[item.title] =
        callback : @emit.bind @, "contextMenuItemClicked", item
        action   : item.action

    @activeFacet = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "active-facet"
      pistachio : "{span{#(title)}}<cite/>"
      click     : (event)=>
        offset = @activeFacet.$().offset()
        event.preventDefault()
        @contextMenu = new JContextMenu
          event       : event
          delegate    : mainView
          x           : offset.left + @activeFacet.getWidth() - 166
          y           : offset.top + 35
          arrow       :
            placement : "top"
            margin    : -20
        , itemsObj
    ,
      title : items.first.title

    return if items.length <= 1
    # mainView.addSubView new KDSelectBox
    #   selectOptions : selectOptions
    #   name          : items.first.action

    mainView.addSubView new KDCustomHTMLView
      tagName  : "span"
      cssClass : "title"
      partial  : "#{title}:"

    mainView.addSubView @activeFacet

    @on "contextMenuItemClicked", (item)=>
      @contextMenu?.destroy()
      @currentItem = item
      @emit "NavItemReceivedClick", item

  selectItem:(item)->
    @currentItem = item
    {title}      = item
    @activeFacet.setData { title }
    @activeFacet.render()
