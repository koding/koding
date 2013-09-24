class EnvironmentContainer extends KDDiaContainer

  constructor:(options={}, data)->
    options.cssClass   = 'environments-container'
    options.draggable ?=
      # axis             : 'y'
      containment      :
        view           : 'parent'
        padding        : 40

    super options, data

    title = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}
    @on "DataLoaded", => @_dataLoaded = yes

    @newItemPlus = new KDCustomHTMLView
      cssClass   : 'new-item-plus'
      click      : => @emit 'PlusButtonClicked'

  viewAppended:->
    super
    @addSubView @header
    @header.addSubView @newItemPlus
    @loadItems()

  addDia:(diaObj, pos)->
    pos = x: 20, y: 60 + @diaCount() * 50
    super diaObj, pos
    @updateHeight()
    diaObj.on "KDObjectWillBeDestroyed", @bound 'updatePositions'

  updatePositions:->
    index = 0
    for _, dia of @dias
      dia.setX 20
      dia.setY 60 + index * 50
      index++
    @updateHeight()

  diaCount:-> Object.keys(@dias).length

  updateHeight:-> @setHeight 80 + @diaCount() * 50

  loadItems:-> yes