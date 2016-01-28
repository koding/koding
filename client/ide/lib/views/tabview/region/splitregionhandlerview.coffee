kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView


module.exports  = class SplitRegionHandlerView extends KDCustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'region', options.direction
    options.bind      = 'dragenter dragleave drop'

    super options, data

    @view = @getOption 'view'


  dragEnter: (event) -> @view.getElement().classList.add 'show'

  dragLeave: (event) -> @view.getElement().classList.remove 'show'

  drop: (event) ->

    { direction } = @getOptions()

    @emit 'TabDropped', direction
