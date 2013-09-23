class EnvironmentItem extends KDDiaObject
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environments-item', options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    options.showStatusIndicator ?= yes
    options.bind = KD.utils.curry 'contextmenu', options.bind

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
    kind = @getOption 'kind'

    ctxMenuContent = {}
    ctxMenuContent['Properties']            =
      callback       : ->
    ctxMenuContent['Focus On This ' + kind] =
      callback       : -> @destroy()
    ctxMenuContent['Unfocus']               =
      callback       : ->
    ctxMenuContent['Edit Bindings']         =
      separator      : yes
      callback       : ->
    ctxMenuContent['Color Tag']             =
      separator      : yes
      children       :
        customView   : new ColorSelection
          parentItem : @
    ctxMenuContent['Rename']                =
      callback       : ->
    ctxMenuContent['Duplicate']             =
      callback       : ->
    ctxMenuContent['Combine Into Group']    =
      callback       : ->
    ctxMenuContent['Delete']                =
      separator      : yes
      callback       : @confirmDestroy
    ctxMenuContent['Create New ' + kind]    =
      callback       : ->
    ctxMenuContent['Create Empty Group']    =
      callback       : ->

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
      ctxMenuContent

  setColorTag : (color) -> @getElement().style.borderLeftColor = color

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
    @setColorTag '#a2a2a2'
    if not @getData().activated
      KD.utils.defer =>
        @setClass 'passivated'
    @addStatusIndicator() if @getOption "showStatusIndicator"

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """

class ColorSelection extends KDCustomHTMLView
  constructor:(options={})->
    options.cssClass = 'environments-cs-container'
    options.colors   = [
      '#a2a2a2'
      '#ffa800'
      '#e13986'
      '#39bce1'
      '#0018ff'
      '#e24d45'
      '#34b700'
      '#a861ff' ]
    super options

  createColors : ->
    for color in @getOption "colors"
      parentItem = @getOption "parentItem"

      @addSubView new KDCustomHTMLView
        cssClass    : "environments-cs-color"
        color       : color
        attributes  :
          style     : "background-color : #{color}"
        click : ->
          parentItem.setColorTag @getOption "color"

  viewAppended : ->
    @createColors()

class EnvironmentRuleItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['right']
    options.cssClass           = 'rule'
    options.kind               = 'Rule'
    options.allowedConnections =
      EnvironmentDomainItem : ['left']
    super options, data

class EnvironmentDomainItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['left', 'right']
    options.cssClass           = 'domain'
    options.kind               = 'Domain'
    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']
    super options, data

class EnvironmentMachineItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['left']
    options.cssClass           = 'machine'
    options.kind               = 'Machine'
    options.allowedConnections =
      EnvironmentDomainItem : ['right']
    super options, data
    @usage = new KDProgressBarView

  viewAppended:->
    super
    @usage.updateBar @getData().usage, '%', ''

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{> @usage}}
      </div>
    """