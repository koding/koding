class EnvironmentMachineContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "vms", ->

    new Promise (resolve, reject)->

      {JVM} = KD.remote.api
      JVM.fetchVmsByContext withStacks:true, (err, vms)->

        if err or vms.length is 0
          warn "Failed to fetch VMs", err  if err
          return resolve []

        resolve vms

  constructor:(options={}, data)->

    options.cssClass   = 'machines'
    options.itemClass  = EnvironmentMachineItem
    options.title      = 'virtual machines'

    super options, data

    # Plus button on machinesContainer uses the vmController
    @on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      @addVmModal = new KDModalView
        title        : 'Add Virtual Machine'
        cssClass     : 'add-vm-modal'
        view         : @getVmSelectionView()
        width        : 786
        overlay      : yes
        buttons      :
          create     :
            title    : "Create"
            style    : "modal-clean-green"
            callback : =>
              {stackId} = @getOptions()
              @addVmModal.destroy()

              KD.singleton("vmController").createNewVM stackId, (err) ->
                KD.showError err

                {dock} = KD.singletons
                log 'dock.refreshSidebarVMs()'

    KD.getSingleton("vmController").on 'VMListChanged', =>
      @loadItems().then => @emit 'VMListChanged'

  loadItems:->

    new Promise (resolve, reject)=>

      vmc = KD.getSingleton 'vmController'

      {entryPoint} = KD.config
      cmd = if entryPoint then 'fetchGroupVMs' else 'fetchVmNames'

      vmc.fetchGroupVMs yes, (err, vms)=>

        @removeAllItems()

        if err or vms.length is 0
          warn "Failed to fetch VMs", err  if err
          return resolve()

        vms.forEach (vm, index)=>
          {hostnameAlias} = vm
          @addItem {
            title     : hostnameAlias
            cpuUsage  : KD.utils.getRandomNumber 100
            memUsage  : KD.utils.getRandomNumber 100
            activated : yes
            hostnameAlias
            vm
          }

          if index is vms.length - 1 then resolve()

  getVmSelectionView: ->

    addVmSelection = new KDCustomHTMLView
      cssClass   : "new-vm-selection"

    addVmSelection.addSubView addVmSmall = new KDCustomHTMLView
      cssClass    : "add-vm-box selected"
      partial     :
        """
          <h3>Small <cite>1x</cite></h3>
          <ul>
            <li><strong>1</strong> CPU</li>
            <li><strong>1GB</strong> RAM</li>
            <li><strong>4GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Large <cite>2x</cite></h3>
          <ul>
            <li><strong>2</strong> CPU</li>
            <li><strong>2GB</strong> RAM</li>
            <li><strong>8GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmExtraLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Extra Large <cite>3x</cite></h3>
          <ul>
            <li><strong>4</strong> CPU</li>
            <li><strong>4GB</strong> RAM</li>
            <li><strong>16GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView comingSoonTitle = new KDCustomHTMLView
      cssClass     : "coming-soon-title"
      tagName      : "h5"
      partial      : "Coming soon..."

    return addVmSelection
