class SplitPlaceholder extends KDView
  viewAppended: ->
    @setClass "split-placeholder"
    @setPartial @partial()

  click: (event) ->
    if $(event.target).is(".startFromScratch")
      @handleEvent type: 'SplittedViewStartFromScratch'
    # else if $(event.target).is(".splitFile")
    #   @handleEvent type: 'SplittedViewSplitFile'
    else if $(event.target).is(".close")
      @handleEvent type: 'SplittedViewClose'
    no

  isDroppable: ->
    yes

  dropAccept: (item) ->
    dropping = item.data('KDPasteboard')
    if dropping and $.isArray(dropping) and dropping.length is 1 and dropping[0] instanceof File
      yes
    else
      no

  dropOver:(event,ui) =>
    ui.helper.addClass 'drop-is-acceptable'

  dropOut: (event, ui) =>
    ui.helper.removeClass 'drop-is-acceptable'

  jQueryDrop: (event, ui) ->
    dropping = ui.draggable.data('KDPasteboard')
    if dropping and $.isArray(dropping) and dropping.length is 1 and dropping[0] instanceof File
      @handleEvent type: 'SplittedViewDroppedFile', file: dropping[0]

  partial: ->
    # <a href='#' class='startFromScratch'>Start from scratch</a> or <a href='#' class='splitFile'>Split file</a> or drag an existing file to activate this view.
    "<div>
    <a href='#' class='startFromScratch'>Start from scratch</a> or drag an existing file to activate this view.
    <br />
    <a href='#' class='close'>Close this split</a>
    </div>"
