groupifyLink = require '../util/groupifyLink'
kd = require 'kd'
JTreeItemView = kd.JTreeItemView
KDCustomHTMLView = kd.CustomHTMLView
AddWorkspaceView = require '../addworkspaceview'
JView = require '../jview'
NavigationMachineItem = require './navigationmachineitem'
NavigationWorkspaceItem = require './navigationworkspaceitem'
SidebarMoreLink = require '../activity/sidebar/sidebarmorelink'


module.exports = class NavigationItem extends JTreeItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.type or= 'main-nav'

    super options, data

    data  = @getData()
    @type = data.type

    if      data.jMachine                then @createMachineItem      data
    else if data.type is 'title'         then @createMoreLink         data
    else if data.type is 'new-workspace' then @createNewWorkspaceView data
    else if data.type is 'workspace'     then @createWorkspaceItem    data
    else if data.type is 'app'           then @createAppItem          data


  createMachineItem: (data) ->

    @type  = 'machine'
    @setClass 'machine'
    @child = new NavigationMachineItem {}, data


  createMoreLink: (data) ->

    @setClass 'sub-title'
    { activitySidebar } = kd.singletons.mainView
    { title } = @getData()
    data.delegate = @getDelegate()

    @child = new SidebarMoreLink
      title   : title
      tagName : 'a'
      click   : (event) ->
        kd.utils.stopDOMEvent event
        activitySidebar.emit 'MoreWorkspaceModalRequested', data


  createWorkspaceItem: (data) ->

    @setClass 'workspace'

    @child = new NavigationWorkspaceItem { delegate: this }, data


  createNewWorkspaceView: ->

    @setClass 'workspace'
    { machineUId, machineLabel } = @getData()

    @child = new AddWorkspaceView {}, { machineUId, machineLabel }


  createAppItem: ->

    @setClass 'app'
    @child    = new KDCustomHTMLView
      partial : """
        <figure></figure>
        <a href='#{groupifyLink data.href}'>#{data.title}</a>
      """


  pistachio: ->
    """
      {{> @child}}
    """



