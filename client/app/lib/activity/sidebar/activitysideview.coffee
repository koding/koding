isChannelCollaborative      = require '../../util/isChannelCollaborative'
kd                          = require 'kd'
KDCustomHTMLView            = kd.CustomHTMLView
KDListViewController        = kd.ListViewController
KDView                      = kd.View
JView                       = require '../../jview'
SidebarMoreLink             = require './sidebarmorelink'


module.exports = class ActivitySideView extends JView

  constructor: (options = {}, data) ->

    options.tagName    or= 'section'
    options.dataSource or= ->

    super options, data

    {itemClass, headerLink, noItemText, searchLink} = @getOptions()
    sidebar = @getDelegate()

    if noItemText
      noItemFoundWidget = new KDCustomHTMLView
        cssClass : 'nothing'
        partial  : noItemText

    @listController = new KDListViewController
      startWithLazyLoader : yes
      noItemFoundWidget   : noItemFoundWidget
      lazyLoaderOptions   :
        spinnerOptions    :
          size            :
            width         : 16
            height        : 16
        partial           : ''
      scrollView          : no
      wrapper             : no
      viewOptions         :
        tagName           : options.viewTagName
        type              : "activities"
        itemClass         : @itemClass or itemClass
        cssClass          : "activities"

    @header = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : @getOption 'title'
      click    : (event) =>
        kd.utils.stopDOMEvent event

        route = if 'add-icon' in event.target.classList
        then event.target.getAttribute 'href'
        else searchLink

        kd.singletons.router.handleRoute route


    @listController.on 'ListIsEmptied', @lazyBound 'setClass', 'empty'
    @listController.on 'ListIsNoMoreEmpty', @lazyBound 'unsetClass', 'empty'

    if headerLink instanceof KDView
    then @header.addSubView headerLink
    else if 'string' is typeof headerLink
      @header.on 'click', =>
        kd.singletons.router.handleRoute headerLink


    @listView = @listController.getView()
    sidebar.bindItemEvents @listView

    @listView.once 'viewAppended', @bound 'init'

    @listView.on 'ItemShouldBeSelected', (item) =>

      return  if sidebar.selectedItem is item

      sidebar.deselectAllItems()
      @listController.selectSingleItem item
      sidebar.selectedItem = item

    {countSource, limit} = @getOptions()
    countSource = kd.utils.debounce 300, countSource  if countSource

    @moreLink = @createMoreLink()
    @moreLink.hide()

    listView = @listController.getListView()
    listView.on 'ItemWasAdded', @bound 'updateCount'
    listView.on 'ItemWasRemoved', @bound 'updateCount'


  updateCount: ->
    @moreLink.updateCount @listController.getItemCount()


  init: ->

    {dataPath} = @getOptions()
    items = kd.singletons.socialapi.getPrefetchedData dataPath

    if items?.length
    then @renderItems null, items
    else @reload()


  reload: ->

    @listController.removeAllItems()
    @listController.showLazyLoader()

    {dataSource} = @getOptions()
    dataSource @bound 'renderItems'


  renderItems: (err, items = []) ->

    {limit} = @getOptions()

    @listController.hideLazyLoader()

    return  if err

    regularItemCount = 0
    index = 0

    loop

      break  if index is items.length

      itemData = items[index]
      index   += 1

      break     if regularItemCount >= limit
      continue  if isChannelCollaborative itemData

      @listController.addItem itemData
      regularItemCount += 1

    kd.utils.defer => @emit 'DataReady', items


  pistachio: ->
    """
    {{> @header}}
    {{> @listView}}
    {{> @moreLink}}
    """


  createMoreLink: ->

    { searchLink, countSource, limit } = @getOptions()

    return new SidebarMoreLink {href: searchLink, countSource, limit}

