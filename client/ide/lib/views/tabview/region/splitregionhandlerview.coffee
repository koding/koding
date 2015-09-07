kd                  = require 'kd'
SplitRegionPartView = require './splitregionpartview'


module.exports  = class SplitRegionHandlerView extends SplitRegionPartView


  constructor: (options = {}, data) ->

    options.bind = 'dragenter dragleave drop'

    super options, data

    @view = @getOption 'view'


  dragEnter: (event) -> @view.getElement().classList.add 'show'

  dragLeave: (event) -> @view.getElement().classList.remove 'show'

  drop: (event) ->

    { direction } = @getOptions()

    @emit 'TabDropped', direction

