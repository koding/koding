class VirtualizationControls extends KDButtonGroupView

  constructor:->
    options =
      cssClass         : "virt-controls"
      buttons          :
        "Start"        :
          callback     : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.start'
        "Stop"         :
          callback     : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.stop'
        "Reinitialize" :
          callback     : ->
            KD.singletons.kiteController.run
              kiteName: 'os',
              method: 'vm.reinitialize'

    super options
