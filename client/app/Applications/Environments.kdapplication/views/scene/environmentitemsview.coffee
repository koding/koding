class EnvironmentItem extends KDDiaObject
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environments-item', options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    options.showStatusIndicator ?= yes

    super options, data

  addStatusIndicator:()->
    @addSubView @statusIndicator = new KDCustomHTMLView
      cssClass    : "status-indicator"
      click       : => @toggleStatus()

  toggleStatus:()->
    @toggleClass "passivated"
    @data.activated = !@data.activated
    @emit 'DiaObjectPassivated' if not @getData().activated

  viewAppended:->
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