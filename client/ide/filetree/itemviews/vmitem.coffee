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

    @vmInfo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-info'
      partial  : "on <strong>#{data.vmName}</strong> VM"

    @vm.fetchVMDomains data.vmName, (err, domains)=>
      if not err and domains.length > 0
        @vmInfo.updatePartial """
          on <a id="open-vm-page-#{data.vmName}"
          href="http://#{domains.first}" target="_blank">
          #{domains.first}</a> VM
        """

  showLoader:->

    @parent?.isLoading = yes
    @loader.show()

  hideLoader:->

    @parent?.isLoading = no
    @loader.hide()


  createRootContextMenu:->
    offset = @changePathButton.$().offset()
    currentPath = @getData().path
    width = 30 + currentPath.length * 3

    contextMenu = new KDContextMenu
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

    vm     = @getData().vmName
    finder = @getData().treeController.getDelegate()

    @utils.defer ->
      parents.forEach (path)->
        contextMenu.treeController.addNode
          title    : path
          callback : ->
            finder?.updateVMRoot vm, path, contextMenu.bound("destroy")

      contextMenu.positionContextMenu()
      contextMenu.treeController.selectFirstNode()

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    if err or not info
      @unsetClass 'online'
      return warn err

    if info.state is "RUNNING"
    then @setClass 'online'
    else @unsetClass 'online'

  viewAppended:->
    super
    @getData().getKite().vmInfo().nodeify @bound 'checkVMState'

  pistachio:->
    path = FSHelper.plainPath @getData().path

    """
      {{> @icon}}
      {{> @loader}}
      {span.title[title="#{path}"]{ #(name)}}
      {{> @changePathButton}}
      {{> @vmInfo}}
      <span class='chevron'></span>
    """
