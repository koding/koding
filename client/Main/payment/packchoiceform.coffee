class PackChoiceForm extends JView
  viewAppended: ->
    { title, itemClass } = @getOptions()

    @titleView = new KDView
      tagName: 'h2'
      partial: title

    @listController = new KDListViewController { itemClass }

    @list = @listController.getListView()

    @list.on 'ItemWasAdded', (item) =>
      item.on 'PackSelected', => @emit 'PackSelected', item.getData()

    super()

  activate: (activator) ->
    @emit 'Activated', activator

  setContents: (contents) ->
    @listController.instantiateListItems contents

  pistachio: ->
    """
    {{> @titleView}}
    {{> @list}}
    """
