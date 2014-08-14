class NavigationMachineItem extends JTreeItemView

  {Running, Stopped} = Machine.State

  stateClasses  = ''
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  JView.mixin @prototype

  constructor:(options = {}, data)->

    machine            = data
    @alias             = machine.label
    path               = KD.utils.groupifyLink "/IDE/VM/#{machine.uid}"

    options.tagName    = 'a'
    options.type     or= 'main-nav'
    options.cssClass   = "vm #{machine.status.state.toLowerCase()}"
    options.attributes =
      href             : path
      title            : "Open IDE for #{@alias}"

    super options, data

    @machine = @getData()
    @progress = new KDProgressBarView
      cssClass : 'hidden'
      # initial  : Math.floor Math.random() * 100

    { computeController } = KD.singletons

    computeController.on "public-#{@machine._id}", (event)=>

      if event.percentage?

        if @progress.bar?

          @progress.show()
          @progress.updateBar event.percentage
          if event.percentage is 100
            KD.utils.wait 1000, @progress.bound 'hide'

      else

        @progress.hide()

      if event.status?

        @unsetClass stateClasses
        @setClass event.status.toLowerCase()


  click: (event)->

    if event.target.tagName.toLowerCase() isnt 'span'
      return yes  if @machine.status.state is Running


  pistachio:->

    """
      <figure></figure>#{@alias}<span></span>
      {{> @progress}}
    """