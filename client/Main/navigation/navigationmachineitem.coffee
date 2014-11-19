class NavigationMachineItem extends JView

  {Running, Stopped} = Machine.State

  stateClasses  = ''
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  constructor: (options = {}, data) ->

    machine            = data
    @alias             = machine.slug or machine.label

    ideRoute           = "/IDE/#{@alias}/my-workspace"
    machineOwner       = machine.jMachine.credential

    unless machineOwner is KD.nick()
      ideRoute         = "#{ideRoute}/#{machineOwner}"

    options.tagName    = 'a'
    options.cssClass   = "vm #{machine.status.state.toLowerCase()} #{machine.provider}"
    options.attributes =
      href             : KD.utils.groupifyLink ideRoute
      title            : "Open IDE for #{@alias}"

    super options, data

    @machine   = @getData()

    @label     = new KDCustomHTMLView
      partial  : machine.label or @alias

    @progress  = new KDProgressBarView
      cssClass : 'hidden'

    KD.singletons.computeController

      .on "public-#{@machine._id}", (event)=>
        @handleMachineEvent event

      # These are updating machine data on this instance indivudally
      # but since we have more data to update, I'm updating all machines
      # for now.
      #
      # .on "revive-#{@machine._id}", (machine)=>
      #   @machine = machine

      #   @label.updatePartial @machine.label
      #   @alias   = @machine.slug or @label
      #   newPath  = KD.utils.groupifyLink "/IDE/#{@alias}/my-workspace"

      #   @setAttributes
      #     href   : newPath
      #     title  : "Open IDE for #{@alias}"


  handleMachineEvent: (event) ->

    {percentage, status} = event

    # switch status
    #   when Machine.State.Terminated then @destroy()
    #  else @setState status

    @setState status

    if percentage?
      @updateProgressBar percentage


  setState: (state) ->

    return  unless state

    @unsetClass stateClasses
    @setClass state.toLowerCase()


  updateProgressBar: (percentage) ->

    return @progress.hide()  unless percentage

    @progress.show()
    @progress.updateBar percentage

    if percentage is 100
      KD.utils.wait 1000, @progress.bound 'hide'


  pistachio:->

    return """
      <figure></figure>
      {{> @label}}
      <span></span>
      {{> @progress}}
    """
