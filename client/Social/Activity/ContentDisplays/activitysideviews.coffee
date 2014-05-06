class ActivitySideView extends JView

  constructor: (options = {}, data) ->

    options.tagName    or= 'section'
    options.dataSource or= ->

    super options, data

    {itemClass} = @getOptions()

    @listController = new KDListViewController
      startWithLazyLoader : yes
      lazyLoaderOptions   : partial : ''
      scrollView          : no
      wrapper             : no
      viewOptions         :
        tagName           : options.viewTagName
        type              : "activities"
        itemClass         : @itemClass or itemClass
        cssClass          : "activities"

    @listView    = @listController.getView()
    @showAllLink = new KDCustomHTMLView
      tagName    : 'a'
      partial    : 'SHOW ALL'

    @listView.once 'viewAppended', @bound 'reload'


  reload: ->

    {dataSource} = @getOptions()
    dataSource @bound 'renderItems'


  renderItems: (err, items = []) ->

    @listController.hideLazyLoader()
    @listController.addItem item for item in items  unless err


  pistachio: ->
    """
    <h3>#{@getOption 'title'}{{> @showAllLink}}</h3>
    {{> @listView}}
    """
