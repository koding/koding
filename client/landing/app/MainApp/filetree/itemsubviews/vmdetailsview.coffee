class NVMDetailsView extends JView

  # cmdCPU = """mpstat | grep -A 5 "%idle" | tail -n 1 | awk -F " " '{print 100 -  $ 12}'a"""
  cmdRX  = """ifconfig eth0 | grep bytes | awk -F ":" '{print $2}' | awk -F " " '{print $1}'"""
  cmdTX  = """ifconfig eth0 | grep bytes | awk -F ":" '{print $3}' | awk -F " " '{print $1}'"""

  constructor:(options, data)->
    super options, data

    @labelRAM = new KDLabelView
      title : '0%'

    @labelRX = new KDLabelView
      title : '0 byte'

    @labelTX = new KDLabelView
      title : '0 byte'

    @vm = KD.getSingleton 'vmController'
    # @vm.on 'StateChanged', @bound 'checkVMState'

  kcRun:(command, callback)->
    kc = KD.singletons.kiteController
    kc.run
      kiteName : "os"
      method   : "exec"
      vmName   : @getData().vmName
      withArgs : command
    , callback

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    console.log vm
    console.log info

    if err or not info
      @labelRAM.updateTitle "0%"
      @labelRX.updateTitle "0 bytes"
      @labelTX.updateTitle "0 bytes"
      return warn err

    console.log vm

    if info.state is "RUNNING"
      # Memory
      mem = (info.memoryUsage / info.memoryLimit * 100).toFixed(2)
      @labelRAM.updateTitle "#{mem}%"
      # RX
      @kcRun cmdRX, (err, out)=>
        bytes = (parseInt(out) / 1024).toFixed(2)
        @labelRX.updateTitle "#{bytes} KBs"
      # TX
      @kcRun cmdTX, (err, out)=>
        bytes = (parseInt(out) / 1024).toFixed(2)
        @labelTX.updateTitle "#{bytes} KBs"


  pistachio:->
    """
    <div class="vm-details-menu">RAM Usage:
      <span class="vm-details-item fr">{{> @labelRAM }}</span>
    </div>
    <div class="vm-details-menu">Received Bytes:
      <span class="vm-details-item fr">{{> @labelRX }}</span>
    </div>
    <div class="vm-details-menu">Transferred Bytes:
      <span class="vm-details-item fr">{{> @labelTX }}</span>
    </div>
    """

  viewAppended:->
    super
    @vm.info @getData().vmName, @bound 'checkVMState'