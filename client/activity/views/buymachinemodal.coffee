class BuyMachineModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'buy-machine-modal activity-modal kdmodal-buttons'
    options.overlay  = yes
    options.width    = 284
    options.height   = 375
    options.position =
      top            : 20
      left           : 255

    super options, data

    @addSubView (new KDCustomHTMLView cssClass: 'modal-arrow'), 'kdmodal-inner', yes

    @createItem @getDefaultPlan()
    @createBuyButton()

    # @createLoader()
    # @fetchPlans()


  fetchPlans: ->
    KD.getSingleton('computeController').fetchAvailable { provider: 'koding' }, (err, instances) =>
      if err
        @destroy()
        return KD.showError err

      @loader.destroy()
      @unsetClass 'loading'

      instances.forEach @bound 'createItem'
      @createBuyButton()


  createLoader: ->
    @setClass 'loading'
    @loader      = new KDLoaderView
      size       :
        width    : 36
        height   : 36
      showLoader : yes

    @addSubView @loader


  createItem: (planData) ->
    {title, spec} = planData
    [name, tag]   = title.split ' '

    @addSubView new KDCustomHTMLView
      cssClass    : "add-vm-box selected"
      partial     :
        """
          <h3>#{name} <cite>#{tag}</cite></h3>
          <ul>
            <li><strong>#{spec.cpu}</strong>CPU</li>
            <li><strong>#{spec.ram}</strong>GB RAM</li>
            <li><strong>#{spec.storage}GB</strong> Storage</li>
          </ul>
        """


  createBuyButton: ->
    @addSubView new KDButtonView
      title    : 'Create'
      cssClass : 'solid green medium create-machine'
      callback : @bound 'createInsance'


  createInsance: ->
    computeController = KD.getSingleton 'computeController'
    instanceName      = 'koding-vm-1'

    computeController.fetchMachines (err, machines) =>
      return KD.showError err  if err

      for machine in machines
        {label} = machine

        if label.indexOf('koding-vm-') > -1
          [koding, vm, number] = label.split '-'
          instanceName = "koding-vm-#{++number}"

      instanceOptions =
        provider      : 'koding'
        instanceType  : 't2.micro'
        label         : instanceName
        stack         : computeController.stacks.first._id

      computeController.create instanceOptions, (err, machine) =>
        return KD.showNotification "Couldn't create your new machine"  if err

        @emit 'MachineCreated', machine
        @destroy()

  getDefaultPlan: ->
    return {
      title     : 'Small 1x'
      name      : 't2.micro'
      price     : 'free'
      spec      : Object
        cpu     : 1
        ram     : 1
        storage : 5
    }
