class FatihPluginAbstract extends KDController

  constructor: (options, data) ->

    options.name                or= "Fatih Plugin"
    options.keyword             or= ""           # plugin keywords should not have a space
    options.notFoundText        or= "Not found!"
    options.showResultIn        or= "fatih"      # "fatih" or "newtab" or "preview"
    options.iconCssClass        or= ""
    options.itemCssClass        or= ""
    options.maxItemCount        or= 4
    options.displayNoResultView or= yes
    options.thirdParty          or= no
    options.itemClickedCallback or= noop
    options.actionCallback      or= noop

    super options, data

    @index        = {}
    @fatihView    = @getDelegate()
    @actionIndex  = 0
    @showAllItems = no

    @on "FatihPluginListItemClicked", (data) =>
      options = @getOptions()
      options.itemClickedCallback data if @options.thirdParty

    @on "FatihQueryPerformed", (keyword) =>
      options       = @getOptions()
      @showAllItems = no
      @actionIndex  = 0

      if @options.thirdParty
        result = options.actionCallback keyword
        @emit "FatihPluginCreatedAList", result if Array.isArray result

      if Array.isArray @action then @emit "FatihNextAction", keyword else @action keyword

    @on "FatihNextAction", =>
      @[@action[@actionIndex++]]?.call @, arguments

    @on "FatihPluginCreatedAList", (list = [], itemClass = FatihListItem, callback = noop) =>
      log "list created", list

      {maxItemCount}  = @getOptions()
      hasMoreItem     = list.length > maxItemCount and not @showAllItems
      items           = if hasMoreItem then list.slice 0, maxItemCount else list

      @createList items, itemClass

      @createShowMoreLink list, itemClass, list.length - maxItemCount if hasMoreItem

      callback()

      @fatihView.emit "PluginViewReadyToShow", @listController.getView()

  createList: (items, itemClass) ->
    @listController = new KDListViewController
      wrapper     : no
      scrollView  : no
      keyNav      : yes
      view        : new KDListView
        keyNav    : yes
        delegate  : @
        tagName   : "ul"
        cssClass  : "fatih-search-results #{@getOptions().itemCssClass}"
        itemClass : itemClass
    , items       : items

  createShowMoreLink: (list, itemClass, diff) ->
    @listController.on "AllItemsAddedToList", =>
      @listController.getView().addSubView new KDView
        cssClass : "fatih-plugin-show-more"
        partial  : "#{diff} more. Click here to see."
        click    : =>
          @showAllItems = yes
          @emit "FatihPluginCreatedAList", list, itemClass

  registerIndex:    -> @index = @generateIndex()

  action: (keyword) -> # TODO: Plugin developer should override this method

  generateIndex   : -> # TODO: Plugin developer should override this method
