class KDDiaContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass  = KD.utils.curryCssClass 'kddia-container', options.cssClass

    if options.draggable
      options.draggable = {}  unless 'object' is typeof options.draggable
      options.draggable.containment or= {}
      options.draggable.containment.view or= 'parent'
      options.draggable.containment.padding ?= x:10, y:10

    super options, data
    @dias = {}

  mouseDown:->
    super
    @emit "HighlightLines", (dia for key, dia of @dias)

  addSubView:(diaObj)->
    super diaObj

    diaObj.on "DiaObjectClicked", => @emit "HighlightLines", diaObj
    @dias[diaObj.getId()] = diaObj
    @emit "NewDiaObjectAdded", this, diaObj
    return diaObj
