class EnvironmentContainer extends KDDiaContainer

  constructor:(options={}, data)->

    options.cssClass   = KD.utils.curry 'environments-container', options.cssClass

    super options, data

    title   = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}

    @itemHeight = options.itemHeight ? 24

    @on "DataLoaded", => @_dataLoaded = yes

    @loader = new KDLoaderView
      cssClass   : 'new-item-loader hidden'
      size       :
        height   : 20
        width    : 20

  viewAppended:->
    super

    @addSubView @header
    @header.addSubView @loader

    @addButton = new KDButtonView
      title    : "+"
      cssClass : 'add-button'
      callback : => @emit 'PlusButtonClicked'
    @addSubView @addButton

    {@appStorage} = @parent

  showLoader: ->
    @newItemPlus.hide()
    @loader.show()

  hideLoader: ->
    @newItemPlus.show()
    @loader.hide()

  addDia:(diaObj, pos)->
    pos = x: 20, y: 68 + @diaCount() * (@itemHeight + 20)
    super diaObj, pos

    diaObj.on "KDObjectWillBeDestroyed", @bound 'updatePositions'
    diaObj.on "KDObjectWillBeDestroyed", => @emit "itemRemoved"
    @updateAddButton()

  updatePositions:->

    index = 0
    for _key, dia of @dias
      dia.setX 20
      dia.setY 68 + index * (@itemHeight + 20)
      index++

    @updateAddButton()

  diaCount:-> Object.keys(@dias).length

  loadItems:->
    @removeAllItems()

  updateAddButton:->
    @addButton.setY 68 + @diaCount() * (@itemHeight + 20)
