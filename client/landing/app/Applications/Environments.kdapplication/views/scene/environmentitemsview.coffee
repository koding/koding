class EnvironmentItem extends KDDiaObject
  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environments-item', options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no

    super options, data

  viewAppended:->
    super

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """

class EnvironmentRuleItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['right']
    options.cssClass = 'rule'
    super options, data

class EnvironmentDomainItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left', 'right']
    options.cssClass = 'domain'
    super options, data

class EnvironmentMachineItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints = ['left']
    options.cssClass = 'machine'
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