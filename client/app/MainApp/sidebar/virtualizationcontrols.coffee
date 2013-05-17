class VirtualizationControls extends JView

  constructor:->

    options = cssClass : "virt-controls"
    super options

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    @statusLED = new StatusLED
      labels   :
        green  : 'VM is running'
        red    : 'VM is turned off'
        yellow : 'VM is initializing'
        off    : '...'

    @statusLED.on 'stateChanged', (state)=>
      state = if state in ['off', 'red'] then no else yes
      @vmToggle.setDefaultValue state

    @vmToggle  = new KDOnOffSwitch
      cssClass : "tiny vm-toggle"
      callback : (state)=>
        if state then @vm.start() else @vm.stop()

    @vmResetButton = new KDButtonView
      cssClass     : "vmreinitialize-button"
      iconOnly     : yes
      iconClass    : "cog"
      tooltip      :
        title      : "Re-initialize your VM"
      callback     : => @vm.reinitialize()

  checkVMState:(err, vm, info)->
    if err or not info
      @statusLED.setOff()
      return warn err

    switch info.state
      when "RUNNING"
        @statusLED.setOnline()
      when "STOPPED"
        @statusLED.setOffline()

  viewAppended:->
    super
    @vm.info @bound 'checkVMState'

  pistachio:->
    """{{> @statusLED}}{{> @vmToggle}}{{> @vmResetButton}}"""

class StatusLED extends JView

  states = ['red', 'yellow', 'green', 'off']

  constructor:(options={})->

    options.cssClass = @utils.curryCssClass "led-wrapper", options.cssClass
    super options

    @label = new KDCustomHTMLView
      cssClass : 'label'

    @setOnline()

  setCurrentState:(state)->
    {labels} = @getOptions()
    @currentState = state

    for _state in states
      if state isnt _state then @unsetClass _state
      else @setClass _state

    if labels
      @label.updatePartial labels[state]

    @emit 'stateChanged', state

  setOff:     -> @setCurrentState 'off'
  setOnline:  -> @setCurrentState 'green'
  setOffline: -> @setCurrentState 'red'
  setWaiting: -> @setCurrentState 'yellow'

  show:-> @unsetClass 'fadeout'
  hide:-> @setClass 'fadeout'

  pistachio:-> """<div class='led'></div>{{> @label}}"""

