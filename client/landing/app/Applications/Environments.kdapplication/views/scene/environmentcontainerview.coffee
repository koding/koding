class EnvironmentContainer extends KDDiaContainer
  constructor:(options={}, data)->
    options.cssClass  = 'environments-container'
    options.draggable = yes
    super options, data

    title = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}

    @newItemPlus = new KDCustomHTMLView
      cssClass   : 'new-item-plus'
      click      : -> @emit 'newItemPlusClicked'

  viewAppended:->
    super
    @addSubView @header
    @header.addSubView @newItemPlus

  addDia:(diaObj, pos)->
    pos = x: 20, y: 60 + @diaCount() * 50
    super diaObj, pos
    @updateHeight()

    diaObj.on "KDObjectWillBeDestroyed", => @refresh diaObj

  refresh:->
    log arguments
    # Recalculate item positions and container height

  diaCount:-> Object.keys(@dias).length
  updateHeight:-> @setHeight 80 + @diaCount() * 50