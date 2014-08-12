class MachineItem extends KDView

  # JView.mixin @prototype

  stateClasses = ""
  for state in Object.keys Machine.State
    stateClasses += "#{state.toLowerCase()} "


  constructor:(options = {}, data)->

    options.cssClass            = "environments-item machine"

    options.disableStateChange ?= no
    options.disableInitialize  ?= no
    options.disableTerminal    ?= no
    options.hideProgressBar    ?= no

    super options, data


  viewAppended:->

    { disableTerminal, disableInitialize
      hideProgressBar, disableStateChange } = @getOptions()

    { label, provider, uid, status } = machine = @getData()
    { Running, NotInitialized, Terminated } = Machine.State

    { computeController } = KD.singletons

    @addSubView new KDCustomHTMLView
      cssClass : 'toggle'
      tagName  : 'span'

    @addSubView @title = new KDCustomHTMLView
      tagName  : 'h3'
      partial  : "#{machine.getName()}<cite>#{provider}</cite>"

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

    @progress.hide()  if hideProgressBar


    @addSubView @terminalIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "terminal"
      click    : @lazyBound "openTerminal", {}

    @terminalIcon.hide()  if disableTerminal

    # FIXME ~ Style trick ~ GG
    if disableStateChange
      @statusToggle.hide()
      @terminalIcon.setClass "terminal-only"


    if status.state in [ NotInitialized, Terminated ] and not disableInitialize
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

  viewAppended:->

    # FIXME later ~ GG
    # Find a better way to filter options

    { disableTerminal, disableInitialize
      hideProgressBar, disableStateChange } = @getOptions()

    @addSubView new MachineItem {
      disableTerminal, disableInitialize
      hideProgressBar, disableStateChange
    }, @getData()
