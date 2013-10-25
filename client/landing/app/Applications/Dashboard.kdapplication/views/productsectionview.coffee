class GroupProductSectionView extends JView

  viewAppended: ->
    console.log "ever fires?"

    group = @getData()

    { category, listControllerClass, itemClass } = @getOptions()

    @setClass "payment-settings-view"

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a #{ category }"
      callback    : =>
        @emit 'CreateRequested'

    @listController = new listControllerClass { group, itemClass }

    @list = @listController.getListView()

    @list.on "DeleteItem", (code) =>
      @emit 'DeleteRequested', code

    super()

  setContents: (contents) ->
    @listController.removeAllItems()
    @listController.instantiateListItems contents