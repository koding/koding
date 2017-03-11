kd = require 'kd'
KDContextMenu = kd.ContextMenu
KDCustomHTMLView = kd.CustomHTMLView
FSHelper = require 'app/util/fs/fshelper'
NFileItemView = require './nfileitemview'


module.exports = class NMachineItemView extends NFileItemView

  constructor: (options = {}, data) ->

    options.cssClass or= 'vm'
    super options, data

    { @machine } = data

    @changePathButton = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'path-select'
      delegate : this
      click    : @bound 'createRootContextMenu'

    @machineInfo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-info'
      partial  : "on <strong>#{@machine.getName()}</strong> VM"

    @setClass 'online'  if @machine.isRunning()

  showLoader: ->

    @parent?.isLoading = yes
    @loader.show()

  hideLoader: ->

    @parent?.isLoading = no
    @loader.hide()


  createRootContextMenu: ->

    offset = @changePathButton.$().offset()
    currentPath = @getData().path
    width = 30 + currentPath.length * 3

    contextMenu = new KDContextMenu
      menuWidth   : width
      delegate    : @changePathButton
      x           : offset.left - 106
      y           : offset.top + 22
      arrow       :
        placement : 'top'
        margin    : 108
      lazyLoad    : yes
    , {}

    parents = []
    nodes = currentPath.split('/')
    for x in [0...nodes.length - 1]
      nodes = currentPath.split('/')
      path  = (nodes.splice 1, x).join '/'
      parents.push "/#{path}"
    parents.reverse()

    { uid } = @machine
    finder  = @getData().treeController.getDelegate()

    kd.utils.defer ->
      parents.forEach (path) ->

        contextMenu.treeController.addNode
          title    : path
          callback : ->
            finder?.updateMachineRoot uid, path, contextMenu.bound('destroy')

      contextMenu.positionContextMenu()
      contextMenu.treeController.selectFirstNode()


  pistachio: ->
    path = FSHelper.plainPath @getData().path

    """
      {{> @icon}}
      {{> @loader}}
      <span title="#{path}">#{@machine.getName()}</span>
      {{> @changePathButton}}
      {{> @machineInfo}}
      <span class='chevron'></span>
    """
