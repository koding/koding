class ActivitySideView extends JView

  constructor: (options = {}, data) ->

    options.tagName    or= 'section'
    options.dataSource or= ->

    super options, data

    {itemClass} = @getOptions()
    sidebar     = @getDelegate()

    @listController = new KDListViewController
      startWithLazyLoader : yes
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
      tagName : 'h3'
      partial : @getOption 'title'
      click   : @bound 'reload'

    @listView = @listController.getView()

    @listView.once 'viewAppended', @bound 'init'

    @listView.on 'ItemShouldBeSelected', (item) =>

      return  if sidebar.selectedItem is item

      sidebar.deselectAllItems()
      @listController.selectSingleItem item
      sidebar.selectedItem = item


  init: ->

    {dataPath} = @getOptions()
    items = KD.singletons.socialapi.getPrefetchedData()[dataPath]
    if items.length
    then @renderItems null, items
    else @reload()


  reload: ->

    @listController.removeAllItems()
    @listController.showLazyLoader()

    {dataSource} = @getOptions()
    dataSource @bound 'renderItems'


  renderItems: (err, items = []) ->

    @listController.hideLazyLoader()
    @listController.addItem item for item in items  unless err


  pistachio: ->
    """
    {{> @header}}
    {{> @listView}}
    """
