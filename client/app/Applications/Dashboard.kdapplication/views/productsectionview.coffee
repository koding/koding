class GroupProductSectionView extends JView

  viewAppended: ->
    group = @getData()

    { category, itemClass } = @getOptions()

    @setClass "payment-settings-view"

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a #{ category }"
      callback    : =>
        @emit 'CreateRequested'

    @listController = new ProductSectionListController { itemClass }

    @list = @listController.getListView()

    @list.on "DeleteItem", (code) =>
      @emit 'DeleteRequested', code

    super()

  setContents: (contents) ->
    @listController.removeAllItems()
    @listController.instantiateListItems contents