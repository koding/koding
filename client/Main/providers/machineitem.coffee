class MachineItem extends KDView

  # JView.mixin @prototype

  stateClasses = ""
  for state in Object.keys Machine.State
    stateClasses += "#{state.toLowerCase()} "

  constructor:(options = {}, data)->

    options.cssClass = "kdview environments-item machine"
    super options, data


  viewAppended:->

    { label, provider, uid, status } = machine = @getData()
    { computeController } = KD.singletons

    { Running, NotInitialized, Terminated } = Machine.State

    @addSubView new KDCustomHTMLView
      partial : "<span class='toggle'></span>"

    @addSubView @title = new KDCustomHTMLView
      partial : "<h3>#{label or provider or uid}<cite>#{provider}</cite></h3>"

    @addSubView @ipAddress = new KDCustomHTMLView
      partial  : @getIpLink()

    @addSubView @state = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "state"

    @addSubView @statusToggle = new KodingSwitch
      cssClass     : "tiny"
      defaultValue : status.state is Running
      callback     : (state)->
        if state
        then computeController.start machine
        else computeController.stop machine

    @addSubView @progress = new KDProgressBarView
      cssClass : "progress"

    @addSubView @terminalIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "terminal"
      click    : @lazyBound "openTerminal", {}

    if status.state in [ NotInitialized, Terminated ]
      @addSubView @initView = new InitializeMachineView
      @initView.on "Initialize", ->
        computeController.build machine
        @setClass 'hidden-all'

    computeController.on "public-#{machine._id}", (event)=>

      if event.percentage?

        if @progress.bar?
          @progress.updateBar event.percentage

        if event.percentage < 100 then @setClass 'loading busy'
        else return KD.utils.wait 1000, =>
          @unsetClass 'loading busy'
          @updateState event

      else

        @unsetClass 'loading busy'

      @updateState event

    computeController.info machine


  updateState:(event)->

    {status, reverted} = event

    return unless status

    {Running, Starting, NotInitialized, Terminated} = Machine.State

    if reverted
      warn "State reverted!"
      if status in [ NotInitialized, Terminated ] and @initView?
        @initView.unsetClass 'hidden-all'

    @unsetClass stateClasses
    @setClass status.toLowerCase()

    if status in [ Running, Starting ]
    then @statusToggle.setOn no
    else @statusToggle.setOff no

    @getData().jMachine.setAt "status.state", status
    @state.updatePartial status


  openTerminal:(options = {})->

    options.machine = @getData()
    new TerminalModal options

  getIpLink:->

    { ipAddress, status:{state} } = @getData().jMachine
    { Running, Rebooting } = Machine.State

    if ipAddress? and state in [ Running, Rebooting ]

      """
        <a href="http://#{ipAddress}" target="_blank" title="#{ipAddress}">
          <span class='url'>#{ipAddress}</span>
        </a>
      """

    else ""


class MachineItemListView extends KDListItemView

  viewAppended:-> @addSubView new MachineItem {}, @getData()
