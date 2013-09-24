class EnvironmentItem extends KDDiaObject

  constructor:(options={}, data)->

    options.cssClass = KD.utils.curry "environments-item", options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    options.showStatusIndicator ?= yes
    options.bind = KD.utils.curry "contextmenu", options.bind
    options.colorTag ?= "#ffa800"
    data.activated   ?= yes

    super options, data

  addStatusIndicator : ->
    @addSubView @statusIndicator = new KDCustomHTMLView
      cssClass    : "status-indicator"
      click       : => @toggleStatus()

  toggleStatus : ->
    @toggleClass "passivated"
    @data.activated = !@data.activated

  contextMenu : (event) ->
    KD.utils.stopDOMEvent event
    kind = @getOption "kind"

    @ctxMenu = new JContextMenu
      menuWidth   : 200
      delegate    : @
      x           : event.pageX + 15
      y           : event.pageY - 23
      arrow       :
        placement : "left"
        margin    : 19
      lazyLoad    : yes
    ,
      'Properties'            :
        callback              : ->
      'Focus On This'         :
        callback              : -> @destroy()
      'Unfocus'               :
        callback              : ->
      'Edit Bindings'         :
        separator             : yes
        callback              : ->
      'Color Tag'             :
        separator             : yes
        children              :
          customView          : @colorSelection = new ColorSelection
            selectedColor     : @getOption 'colorTag'
      'Rename'                :
        callback              : ->
      'Duplicate'             :
        callback              : ->
      'Combine Into Group'    :
        callback              : ->
      'Delete'                :
        separator             : yes
        callback              : =>
          @ctxMenu.destroy()
          @confirmDestroy()
      'Create New'            :
        callback              : ->
      'Create Empty Group'    :
        callback              : ->

    @colorSelection.on "ColorChanged", (color) => @setColorTag color

  setColorTag : (color) ->
    @getElement().style.borderLeftColor = color
    @options.colorTag                   = color

  confirmDestroy : =>
    modal        = new KDModalView
      title      : "Are you sure?"
      cssClass   : "environments-confirm-destroy"
      content    : "<div><strong>\"#{@getData().title}\"</strong> item will be deleted. Please confirm.</div>"
      buttons    :
        confirm         :
          title         : "Delete"
          style         : "modal-clean-red"
          callback      : =>
            modal.destroy()
            @destroy()
        cancel          :
          title         : "Cancel"
          style         : "modal-cancel"
          callback      : (event)-> modal.destroy()

  viewAppended : ->
    super
    @setClass 'activated'  if @getData().activated?
    if not @getData().activated
      KD.utils.defer =>
        @setClass 'passivated'
    @addStatusIndicator() if @getOption "showStatusIndicator"
    @setColorTag @getOption('colorTag')

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """
