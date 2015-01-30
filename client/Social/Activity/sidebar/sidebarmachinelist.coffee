class SidebarMachineList extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName        = 'section'
    options.title        or= ''
    options.cssClass       = KD.utils.curry 'vms', options.cssClass
    options.hasPlusIcon   ?= no

    super options, data

    @createHeader()
    @addMachineBoxes()


  createHeader: ->

    @header = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : options.title
      click    : => @emit 'ListHeaderClicked'

    if options.hasPlusIcon
      @header.addSubView new CustomLinkView
        cssClass : 'add-icon buy-vm'
        title    : ' '
        click    : (e) =>
          KD.utils.stopDOMEvent e
          @emit 'ListHeaderPlusIconClicked'

    @addSubView @header


  addMachineBoxes: ->

    @machineBoxes = []

    for machineData in data

      machineBox = new SidebarMachineBox {}, machineData
      @addSubView machineBox
      @machineBoxes.push machineBox
