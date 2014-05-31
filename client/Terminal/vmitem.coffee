class TerminalStartTabVMItem extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.tagName  = 'li'
    options.cssClass = KD.utils.curry 'vm-loader-item', options.cssClass

    super options, data

    @machine = @getData()

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes
      loaderOptions :
        color       : '#ffffff'

    @notice = new KDCustomHTMLView
      tagName : 'i'
      partial : 'LOADING'

    @progress = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'vm-loader'

    @alwaysOn = new KDCustomHTMLView
      tagName  : 'cite'
      partial  : if @machine.alwaysOn then "always-on" else ""

    @once 'viewAppended', =>
      @setClass 'ready'
      @notice.updatePartial 'READY'
      @loader.hide()


  click: -> @emit 'VMItemClicked', { @machine }


  pistachio: ->

    name = @machine.getName()

    """
    <figure>{{> @loader}}</figure>#{name.replace 'koding.kd.io', 'kd.io'} {{> @alwaysOn}} {{> @notice}}
    {{> @progress}}
    """


  # handleVMStart:(update)->
  #   { message, currentStep, totalStep } = update

  #   if message is 'FINISHED'
  #     @setClass 'ready'
  #     @emit 'vm.is.prepared'
  #     @notice.updatePartial 'READY'
  #     @loader.hide()
  #     return

  #   @unsetClass 'off ready'

  #   if message is 'STARTED'
  #     # @loader.canvas.setColor "#1aaf5d"
  #     @loader.show()
  #     @progress.setCss 'background-color', "#1aaf5d"
  #     return
  #   percentage = Math.round currentStep/totalStep*100
  #   @progress.setWidth percentage, '%'
  #   @notice.updatePartial "#{percentage}%"


  # handleVMStop:(update)->
  #   { message, currentStep, totalStep } = update
  #   return @renderVMStop()  if message is 'FINISHED'

  #   @unsetClass 'off ready'
  #   # niceMessage = MESSAGE_MAP[message.toLowerCase()]
  #   # @notice.updatePartial niceMessage or message
  #   if message is 'STARTED'
  #     # @loader.canvas.setColor "#FF7379"
  #     @loader.show()
  #     @progress.setCss 'background-color', "#FF7379"
  #     @notice.updatePartial "100%"
  #     @progress.setWidth 100, '%'
  #     return
  #   percentage = 100 - Math.round currentStep/totalStep*100
  #   @progress.setWidth percentage, '%'
  #   @notice.updatePartial "#{percentage}%"


  # handleVMInfo:(info)->
  #   unless info
  #     @unsetClass 'ready off'
  #     @loader.show()
  #     @notice.updatePartial 'LOADING'
  #     @progress.setWidth 0, '%'
  #     return

  #   { state } = info
  #   switch state.toLowerCase()
  #     when "running"
  #       @loader.hide()
  #       @unsetClass 'off'
  #       @notice.updatePartial 'READY'
  #       @setClass 'ready'
  #     when "stopped"
  #       @unsetClass 'ready'
  #       @renderVMStop()

  # handleVMError:(error)->
  #   @renderVMStop()

  # renderVMStop: ->
  #   @loader.hide()
  #   @setClass 'off'
  #   @notice.updatePartial 'OFF'
