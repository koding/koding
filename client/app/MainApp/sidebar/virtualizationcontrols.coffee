class VirtualizationControls extends JView

  constructor:->

    options =
      cssClass         : "virt-controls"
    super options

    @statusLED = new StatusLED
      labels    :
        green   : 'VM is running'
        red     : 'VM is turned off'
        yellow  : 'VM is initializing'
        off     : '...'

    @VMToggle = new KDOnOffSwitch
      cssClass        : "tiny vm-toggle"
      callback        : (state)->
        command = if state then 'vm.start' else 'vm.stop'
        log "runnung", state,command
        KD.singletons.kiteController.run
          kiteName : 'os'
          method   : command

  pistachio:->
    """{{> @statusLED}}{{> @VMToggle}}"""

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

  setOff:     -> @setCurrentState 'off'
  setOnline:  -> @setCurrentState 'green'
  setOffline: -> @setCurrentState 'red'
  setWaiting: -> @setCurrentState 'yellow'

  show:-> @unsetClass 'fadeout'
  hide:-> @setClass 'fadeout'

  pistachio:-> """<div class='led'></div>{{> @label}}"""