class TerminalStartTabVMItem extends KDCustomHTMLView

  MESSAGE_MAP =
    'started'                : 'Checking VM state'
    'vm is already prepared' : 'READY'

  constructor:(options = {}, data)->

    options.tagName = 'li'
    options.cssClass = KD.utils.curry 'vm-loader-item', options.cssClass

    super options, data

    vm               = @getData()
    { vmController } = KD.singletons

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes
      loaderOptions :
        color       : '#f2f2f2'

    @notice = new KDCustomHTMLView
      tagName : 'i'
      partial : '0%'


  handleVMStart:(update)->

    { message, currentStep, totalStep } = update
    if message is 'FINISHED'
      @setClass 'ready'
      @emit 'vm.is.prepared'
      @notice.updatePartial 'READY'
      @loader.hide()
      return

    @unsetClass 'off ready'
    # niceMessage = MESSAGE_MAP[message.toLowerCase()]
    # @notice.updatePartial niceMessage or message

    return if message is 'STARTED'
    @notice.updatePartial "#{Math.round(currentStep/totalStep*100)}%"


  handleVMStop:(update)->

    { message, currentStep, totalStep } = update
    if message is 'FINISHED'
      @setClass 'off'
      @notice.updatePartial 'OFF'
      @loader.hide()
      return

    @unsetClass 'off ready'
    # niceMessage = MESSAGE_MAP[message.toLowerCase()]
    # @notice.updatePartial niceMessage or message
    return if message is 'STARTED'
    @notice.updatePartial "#{100-Math.round(currentStep/totalStep*100)}%"


  handleVMInfo:(info)->

    unless info
      @loader.hide()
      @notice.updatePartial 'FAILED'
      return

    { state } = info
    switch state.toLowerCase()
      when "running"
        @notice.updatePartial 'READY'
        @setClass 'ready'
      when "stopped"
        @setClass 'off'
        @notice.updatePartial 'OFF'

    @loader.hide()

  click : ->

    osKite = KD.singletons.vmController.kites[@getData().hostnameAlias]

    if @hasClass 'ready'
      @emit 'VMItemClicked', @getData()
    else if @hasClass 'off'
      @once "vm.is.prepared", => @emit 'VMItemClicked', @getData()
      osKite?.vmOn()
    else
      osKite?.vmOff()



  viewAppended:JView::viewAppended


  pistachio:->
    vm    = @getData()
    alias = vm.hostnameAlias
    """
    <figure>{{> @loader}}</figure>#{alias.replace 'koding.kd.io', 'kd.io'}{{> @notice}}
    """

