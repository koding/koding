class HeaderNavigationController extends KDController

  constructor:(options, data)->

    super

    mainView = @getDelegate()

    {items, title} = @getData()

    selectOptions = for item in items
      { title : item.title, value : item.type }

    mainView.addSubView new KDSelectBox
      selectOptions : selectOptions
      name          : items.first.action
