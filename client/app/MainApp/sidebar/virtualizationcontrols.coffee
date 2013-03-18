class VirtualizationControls extends KDButtonGroupView

  constructor:->
    options =
      cssClass      : "virt-controls"
      buttons       :
        "Start"     :
          callback  : -> log "Start machine"
        "Stop"      :
          callback  : -> log "Stop machine"
        "Turn Off"  :
          callback  : -> log "Turn off machine"

    super options
