class KDDiaContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'kddia-container', options.cssClass

    if options.draggable
      options.draggable = {}  unless 'object' is typeof options.draggable

    options.itemClass ?= KDDiaObject
    super options, data
    @dias = {}

  mouseDown:->
    super
    @emit "HighlightDia", (dia for key, dia of @dias)

  addDia:(diaObj, pos = {})->
    @addSubView diaObj
    diaObj.on "DiaObjectClicked",    => @emit "HighlightDia", diaObj
    diaObj.on "RemoveMyConnections", => delete @dias[diaObj.getId()]

    @dias[diaObj.getId()] = diaObj
    @emit "NewDiaObjectAdded", this, diaObj

    diaObj.setX pos.x  if pos.x?
    diaObj.setY pos.y  if pos.y?

    return diaObj

  addItem:(data, options={})->
    itemClass = @getOption 'itemClass'
    @addDia new itemClass options, data

  removeAllItems:->
    dia.destroy?() for _, dia of @dias

  setScale:(scale=1)->
    props = ['webkitTransform', 'MozTransform', 'transform']
    css   = {}
    css[prop] = "scale(#{scale})"  for prop in props
    @setStyle css

