class ComputeProvider extends KDObject

  @providers = KD.config.providers

  @fetchStacks = (callback = noop)->

    if @stacks
      callback null, @stacks
      info "Stacks returned from cache."
      return

    KD.remote.api.JStack.some {}, (err, stacks = [])->
      return callback err  if err?
      callback null, ComputeProvider.stacks = stacks


  @fetchMachines = (callback)->

    @fetchStacks (err, stacks)->
      return callback err  if err?

      machines = []
      stacks.forEach (stack)->
        stack.machines.forEach (machine)->
          machines.push new Machine { machine }

      callback null, machines


  @credentialsFor = (provider, callback)->
    KD.remote.api.JCredential.some { provider }, callback

  @fetchAvailable = (options, callback)->
    KD.remote.api.ComputeProvider.fetchAvailable options, callback

  @fetchExisting = (options, callback)->
    KD.remote.api.ComputeProvider.fetchExisting options, callback

  @create = (options, callback)->
    KD.remote.api.ComputeProvider.create options, callback

  @createDefaultStack = ->
    KD.remote.api.ComputeProvider.createGroupStack (err, stack)->
      return if KD.showError err

      delete ComputeProvider.stacks
      KD.singletons.mainController.emit "renderStacks"


class Machine extends KDObject

  constructor:(options = {})->

    { machine } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      throw new Error 'Data should be a JMachine instance'

    delete options.machine
    super options, machine

    { @label, @publicAddress, @state, @uid, @_id } = @jMachine = @getData()

    @kites = {}

    {kontrolProd} = KD.singletons

    @kites.klient = kontrolProd.getKite
      name        : "klient"
      username    : KD.nick()
      environment : "public-host"
      id          : "007"

  getName:->
    @publicAddress or @uid or @label or "one of #{KD.nick()}'s machine"


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

class MachineList extends KDModalView

  constructor: (options = {}, data)->

    options = $.extend
      title    : "Machine List"
      cssClass : "github-modal"
      width    : 540
      overlay  : yes
    , options

    super options, data

  viewAppended:->

    @addSubView @loader = new KDLoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 16

    @addSubView @container = new KDView
      cssClass : 'hidden'

    @machineListController = new KDListViewController
      viewOptions       :
        type            : 'machine'
        wrapper         : yes
        itemClass       : MachineItem
        itemOptions     :
          buttonTitle   : 'select'
      noItemFoundWidget : new KDView
        cssClass        : 'noitem-warning'
        partial         : "There is no machine to show for now."

    @container.addSubView \
      @machineListView = @machineListController.getView()

    @forwardEvent @machineListView, 'MachineSelected'

    @fetchMachines()

  fetchMachines: ->

    @loader.show()

    ComputeProvider.fetchMachines (err, machines)=>
      # TODO handle errors correctly
      return if KD.showError err

      @container.show()
      @loader.hide()

      @machineListController.replaceAllItems machines
