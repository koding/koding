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