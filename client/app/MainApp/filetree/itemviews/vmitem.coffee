class NVMItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass or= "vm"
    super options, data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    @changePathButton = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'path-select'
      delegate : @
      click    : @bound "createRootContextMenu"

  createRootContextMenu:->
    offset = @changePathButton.$().offset()
    finder = KD.getSingleton('finderController')
    currentPath = @getData().path
    width = 30 + currentPath.length * 6

    contextMenu = new JContextMenu
      menuWidth   : width
      delegate    : @changePathButton
      x           : offset.left - 106
      y           : offset.top + 22
      arrow       :
        placement : "top"
        margin    : 108
      lazyLoad    : yes
    , {}

    parents = []
    nodes = currentPath.split('/')
    for x in [0...nodes.length-1]
      nodes = currentPath.split('/')
      path  = (nodes.splice 1,x).join "/"
      parents.push "/#{path}"
    parents.reverse()

    for path in parents
      contextMenu.treeController.addNode
        title    : path
        callback : finder.createRootStructure.bind finder, path, \
                   contextMenu.bound("destroy")

    contextMenu.positionContextMenu()
    contextMenu.treeController.selectFirstNode()

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    if err or not info
      @unsetClass 'online'
      # @vmToggle.setDefaultValue no
      return warn err

    switch info.state
      when "RUNNING"
        @setClass 'online'
        # @vmToggle.setDefaultValue yes

      when "STOPPED"
        @unsetClass 'online'
        # @vmToggle.setDefaultValue no

  viewAppended:->
    super
    @vm.info @bound 'checkVMState'

  pistachio:->

    """
      {{> @icon}}
      {{> @loader}}
      {span.title{ #(name)}}
      {{> @changePathButton}}
      <span class='chevron'></span>
    """
