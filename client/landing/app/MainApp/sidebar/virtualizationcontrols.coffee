class VirtualizationControls extends KDButtonGroupView

  constructor:->
    options =
      cssClass      : "virt-controls"
      buttons       :
        "Start"     :
          callback  : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.start'
        "Stop"      :
          callback  : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.stop'
        "Nuke"      :
          callback  : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.nuke'

    super options
