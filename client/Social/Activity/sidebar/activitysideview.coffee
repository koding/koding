class ActivitySideView extends JView

  constructor: (options = {}, data) ->

    options.tagName    or= 'section'
    options.dataSource or= ->

    super options, data

    {itemClass, headerLink, noItemText} = @getOptions()
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
      # click   : @bound 'reload'


    if headerLink instanceof KDView
    then @header.addSubView headerLink
    else if 'string' is typeof headerLink
      @header.on 'click', =>
        KD.singletons.router.handleRoute headerLink


    @listView = @listController.getView()
    sidebar.bindItemEvents @listView

    @listView.once 'viewAppended', @bound 'init'

    @listView.on 'ItemShouldBeSelected', (item) =>

      return  if sidebar.selectedItem is item

      sidebar.deselectAllItems()
      @listController.selectSingleItem item
      sidebar.selectedItem = item


  init: ->

    {dataPath} = @getOptions()
    items = KD.singletons.socialapi.getPrefetchedData dataPath
    if items?.length
    then @renderItems null, items
    else @reload()


  reload: ->

    @listController.removeAllItems()
    @listController.showLazyLoader()

    {dataSource} = @getOptions()
    dataSource @bound 'renderItems'


  renderItems: (err, items = []) ->

    @listController.hideLazyLoader()

    return  if err

    @listController.addItem itemData for itemData in items


  pistachio: ->
    """
    {{> @header}}
    {{> @listView}}
    """
