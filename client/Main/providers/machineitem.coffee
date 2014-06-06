class MachineItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.type = 'machine'
    options.buttonTitle or= 'select'
    super options, data

    machineReady = data.jMachine.state isnt 'NotInitialized'

    @actionButton = new KDButtonView
      title    : @getOption 'buttonTitle'
      cssClass : 'solid green mini action-button'
      callback : =>
        @getDelegate().emit "MachineSelected", @getData()
      disabled : machineReady

    @setClass 'disabled'  if machineReady

  pistachio:->

    {label, description, html_url} = @getData()

    """
    {h1{#(jMachine.uid)}}
    {{> @actionButton}}
    """

