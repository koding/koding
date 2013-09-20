class EnvironmentContainer extends KDDiaContainer
  constructor:(options={}, data)->
    options.cssClass  = 'environments-container'
    options.draggable = yes
    super options, data

    title = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}

  viewAppended:->
    super
    @addSubView @header

  addDia:(diaObj, pos)->
    pos = x: 20, y: 60 + @diaCount() * 50
    super diaObj, pos
    @updateHeight()
    diaObj.on "KDObjectWillBeDestroyed", @refresh

  refresh:=>
    @updateHeight()
    for key, dia of @dias
      #setY 
    

  diaCount:-> Object.keys(@dias).length
  updateHeight:-> @setHeight 80 + @diaCount() * 50