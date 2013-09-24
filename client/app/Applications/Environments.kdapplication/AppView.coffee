class EnvironmentsMainView extends JView

  constructor:->
    super cssClass : 'environment-content'

  viewAppended:->

    # Main Header
    @addSubView new HeaderViewSection type : "big", title : "Environments"

    # Action Area for Domains
    @addSubView @actionArea = new KDView cssClass : 'action-area'

    # Domain Creation form in actionArea
    @actionArea.addSubView @domainCreateForm = new DomainCreationForm

    # Domain Creation form connections
    @domainCreateForm.on 'DomainCreationCancelled', => @actionArea.unsetClass 'in'
    @domainCreateForm.on 'CloseClicked', => @actionArea.unsetClass 'in'

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    # Domains Container
    @domainsContainer  = new EnvironmentDomainContainer
    @scene.addContainer @domainsContainer

    # VMs / Machines Container
    @machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer @machinesContainer, x: 300

    # After Domains and Machines container load finished
    # Call updateConnections to draw lines between corresponding objects
    @scene.whenItemsLoadedFor \
      [@domainsContainer, @machinesContainer], @bound 'updateConnections'

    @domainCreateForm.on 'DomainSaved', =>
      @domainsContainer.once "DataLoaded", @bound 'updateConnections'
      @domainsContainer.loadItems()

    # Plus button on domainsContainer opens up the action area
    @domainsContainer.on 'PlusButtonClicked', =>
      @actionArea.setClass 'in'
      @domainCreateForm.emit 'DomainNameShouldFocus'
      # @domainsContainer.loadItems()

    # Plus button on machinesContainer uses the vmController
    @machinesContainer.on 'PlusButtonClicked', =>
      KD.getSingleton('vmController').createNewVM()

  updateConnections:->
    for _, machine of @machinesContainer.dias
      for _, domain of @domainsContainer.dias
        if domain.data.aliases and machine.data.title in domain.data.aliases
          @scene.connect \
            {dia : domain , joint : 'right', container: @domainsContainer}, \
            {dia : machine, joint : 'left',  container: @machinesContainer}


#  - DO NOT TOUCH BELOW

#   tabData = [
#     name        : 'Domains'
#     viewOptions :
#       viewClass : DomainsMainView
#   ,
#     name        : 'VMS'
#     viewOptions :
#       viewClass : VMsMainView
#   ,
#     name        : 'Kites'
#     viewOptions :
#       viewClass : KDView
#   ,
#     name        : 'Builder'
#     viewOptions :
#       viewClass : EnvironmentScene
#   ]

#   navData =
#     title : "Settings"
#     items : ({title:item.name, hiddenHandle:'hidden'} for item in tabData)

#   constructor:(options = {}, data = {})->
#     super options, data

#     @header = new HeaderViewSection type : "big", title : "Environments"

#     # * see the note below *
#     @nav = new KDView
#       tagName  : "ul"
#       cssClass : "kdlistview kdlistview-default"

#     @utils.defer => @nav.unsetClass "kdtabhandlecontainer"

#     @tabs   = new KDTabView
#       cssClass           : 'environment-content'
#       tabHandleContainer : @nav
#       tabHandleClass     : EnvironmentsTabHandleView
#     , data

#     @listenWindowResize()

#     @once 'viewAppended', =>
#       @createTabs()
#       @_windowDidResize()

#   createTabs:->
#     for {name, viewOptions}, i in tabData
#       @tabs.addPane (new KDTabPaneView {name, viewOptions}), i is 0

#   _windowDidResize:->
#     contentHeight = @getHeight() - @header.getHeight()
#     @$('>section, >aside').height contentHeight

#   pistachio:->
#     """
#       {{> @header}}
#       <aside class='fl'>
#         <div class="kdview common-inner-nav">
#           <div class="kdview listview-wrapper list">
#             <h4 class="kdview kdheaderview list-group-title"><span>MANAGE</span></h4>
#             {{> @nav}}
#           </div>
#         </div>
#       </aside>
#       <section class='right-overflow'>
#         {{> @tabs}}
#       </section>
#     """

# # take this to its own file - SY

# class EnvironmentsTabHandleView extends KDTabHandleView

#   constructor:(options={}, data)->
#     # * see the note below *
#     options.tagName  = 'li'
#     options.closable = no
#     options.cssClass = 'kdview kdlistitemview kdlistitemview-default'

#     super options, data

#     @unsetClass 'kdtabhandle'

#   click: do->
#     notification = null
#     ->
#       unless @getOptions().title is "Domains"
#         notification?.destroy()
#         notification = new KDNotificationView title : 'Coming soon...'
#         return no


#   partial:-> "<a href='#'>#{@getOptions().title or 'Default Title'}</a>"

# # * quick hack: don't copy/paste from here :)
# #   faking a listitem to be able to use same styles
# #   very narrow usage this is acceptable under the circumstances. SY
