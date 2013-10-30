class GroupProductSectionView extends JView

  viewAppended: ->
    { category, itemClass } = @getOptions()

    @setClass "payment-settings-view"

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a #{ category }"
      callback    : =>
        @emit 'CreateRequested'

    @listController = new ProductSectionListController { itemClass }

    @list = @listController.getListView()

    @list.on "ItemWasAdded", (item) =>
      @forwardEvents item, [
        'DeleteRequested'
        'EditRequested'
        'BuyersReportRequested'
      ]

    super()

  setContents: (contents) ->
    @listController.removeAllItems()
    @listController.instantiateListItems contents
