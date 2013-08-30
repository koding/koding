class NVMDetailsView extends JView

  # cmdCPU = """mpstat | grep -A 5 "%idle" | tail -n 1 | awk -F " " '{print 100 -  $ 12}'a"""
  # cmdRX  = """ifconfig eth0 | grep bytes | awk -F ":" '{print $2}' | awk -F " " '{print $1}'"""
  # cmdTX  = """ifconfig eth0 | grep bytes | awk -F ":" '{print $3}' | awk -F " " '{print $1}'"""

  constructor:(options, data)->
    super options, data

    # @labelRAM = new KDLabelView
    #   title : '0 MB / 0 MB'
    @RAMLine  = new KDCustomHTMLView
      cssClass  : "vm-details-menu"
      partial   : "RAM Usage"

    @RAMLine.addSubView @RAMBarWrapper = new KDCustomHTMLView
      tagname   : "span"
      cssClass  : "vm-details-item fr"

    @RAMBarWrapper.addSubView @RAMBar = new KDProgressBarView
      cssClass  : "ram-bar"

    # @labelRX = new KDLabelView
    #   title : '0 byte'

    # @labelTX = new KDLabelView
    #   title : '0 byte'

    @vm = KD.getSingleton 'vmController'
    # @vm.on 'StateChanged', @bound 'checkVMState'

  kcRun:(command, callback)->
    kc = KD.getSingleton("vmController")
    kc.run
      method   : "exec"
      vmName   : @getData().vmName
      withArgs : command
    , callback

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    if err or not info
      # @labelRAM.updateTitle "0%"
      @RAMBar.updateBar "0%","0%"
      # @labelRX.updateTitle "0 bytes"
      # @labelTX.updateTitle "0 bytes"
      return warn err

    if info.state is "RUNNING"
      memUsageInPercentage = ((info.memoryUsage * 100) / info.totalMemoryLimit).toFixed(2)

      #convert bytes into mb
      memUsageInMB = (info.memoryUsage / 1024 / 1024).toFixed(2)
      totalMemoryLimitInMB = info.totalMemoryLimit / 1024 / 1024

      # @labelRAM.updateTitle "#{memUsageInMB} MB (#{memUsageInPercentage}%) of #{totalMemoryLimitInMB} MB"
      # RX
      @RAMBar.updateBar "#{memUsageInPercentage}", "%", "#{memUsageInPercentage}%"

      @RAMLine.setTooltip 
        title     : "#{memUsageInMB} MB of #{totalMemoryLimitInMB} MB"
        placement : "right"
        delayIn   : 300
        offset    :
          top     : 8
          left    : 2

      # @kcRun cmdRX, (err, out)=>
      #   bytes = (parseInt(out) / 1024).toFixed(2)
      #   @labelRX.updateTitle "#{bytes} KBs"
      # # TX
      # @kcRun cmdTX, (err, out)=>
      #   bytes = (parseInt(out) / 1024).toFixed(2)
      #   @labelTX.updateTitle "#{bytes} KBs"


  pistachio:->
    """
    {{> @RAMLine}}
    """
    # <div class="vm-details-menu">Received Bytes:
    #   <span class="vm-details-item fr">{{> @labelRX }}</span>
    # </div>
    # <div class="vm-details-menu">Transferred Bytes:
    #   <span class="vm-details-item fr">{{> @labelTX }}</span>
    # </div>

  viewAppended:->
    super
    @vm.info @getData().vmName, @bound 'checkVMState'
