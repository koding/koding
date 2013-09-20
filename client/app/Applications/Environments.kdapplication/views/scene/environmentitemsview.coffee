class EnvironmentItem extends KDDiaObject
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environments-item', options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    options.showStatusIndicator ?= yes

    super options, data

  addStatusIndicator : ->
    @addSubView @statusIndicator = new KDCustomHTMLView
      cssClass    : "status-indicator"
      click       : => @toggleStatus()

  toggleStatus : ->
    @toggleClass "passivated"
    @data.activated = !@data.activated
    @emit 'DiaObjectPassivated' if not @getData().activated

  dblClick : (event) ->
    @contextMenu = new JContextMenu
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
        callback              : =>
      'Focus On This Rule'    :
        callback              : =>
      'Unfocus'               :
        callback              : =>
      'Edit Bindings'         :
        separator             : yes
        callback              : =>
      'Color Tag'             :
        separator             : yes
        callback              : =>
      'Rename'                :
        callback              : =>
      'Duplicate'             :
        callback              : =>
      'Combine Into Group...' :
        callback              : =>
      'Delete'                :
        separator             : yes
        callback              : @_confirmDestroy
      'Create New Rule...'    :
        callback              : =>
      'Create Empty Group'    :
        callback              : =>

  _confirmDestroy : =>
    parent       = @parent
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
        @emit 'DiaObjectPassivated'
    @addStatusIndicator() if @getOption "showStatusIndicator"

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """

class EnvironmentRuleItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['right']
    options.cssClass           = 'rule'
    options.allowedConnections =
      EnvironmentDomainItem : ['left']
    super options, data

class EnvironmentDomainItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left', 'right']
    options.cssClass = 'domain'
    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']
    super options, data

class EnvironmentMachineItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left']
    options.cssClass = 'machine'
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