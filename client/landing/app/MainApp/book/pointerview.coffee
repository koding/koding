class PointerView extends KDCustomHTMLView

  constructor:(options={}, data)->

    options.partial  = ''
    options.cssClass = 'pointer'

    super options, data

    @bindTransitionEnd()

  destroy:->

    @once 'transitionend', KDCustomHTMLView::destroy.bind this
    @setClass 'out'