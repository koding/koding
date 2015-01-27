class SidebarMachineList extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName        = 'section'
    options.title        or= ''
    options.cssClass       = KD.utils.curry 'vms', options.cssClass
    options.hasPlusIcon   ?= no

    super options, data

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

    for machineData in data
      @addSubView new SidebarMachineBox {}, machineData
