class KDDiaContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curryCssClass 'kddia-container', options.cssClass
    options.draggable = yes
    super options, data
    @dias = {}

  addDia:(type='square')->
    diaObj = new KDDiaObject {type}
    @dias[diaObj.getId()] = diaObj
    @addSubView diaObj
    @emit "NewDiaObjectAdded", this, diaObj
    return diaObj

  viewAppended:->
    super
    @addDia 'circle'
    @addDia 'square'
    @addDia 'circle'
