class EnvironmentScene extends KDDiaScene

  containerMap =
    EnvironmentRuleContainer    : 'rules'
    EnvironmentExtraContainer   : 'extras'
    EnvironmentDomainContainer  : 'domains'
    EnvironmentMachineContainer : 'machines'

  itemMap      =
    EnvironmentRuleItem         : 'rule'
    EnvironmentExtraItem        : 'extra'
    EnvironmentDomainItem       : 'domain'
    EnvironmentMachineItem      : 'machine'

  constructor:->
    super
      cssClass  : 'environments-scene'
      lineWidth : 2

    @boxes = {}

    sc = KD.getSingleton 'appStorageController'
    @appStorage = sc.storage 'EnvironmentsScene', '1.0.1'

  disconnect:(dia, joint)->

    removeConnection = => KDDiaScene::disconnect.call this, dia, joint
    targetConnection = @findTargetConnection dia, joint
    return unless targetConnection
    {source, target} = targetConnection

    items = parseItems source, target
    return  if Object.keys(items).length < 2
    {domain, machine, rule, extra} = items

    if domain and machine
      jDomain = domain.dia.getData().domain # JDomain
      vmName  = machine.dia.getData().title # JVM.hostnameAlias
      jDomain.unbindVM hostnameAlias: vmName, (err)=>
        return KD.showError err  if err
        jDomain.hostnameAlias.splice jDomain.hostnameAlias.indexOf(vmName), 1
        removeConnection()
    else if domain and rule
      removeConnection()
    else if machine and extra
      removeConnection()

  connect:(source, target, internal = no)->

    createConnection = => KDDiaScene::connect.call this, source, target

    return createConnection()  if internal

    if not @allowedToConnect source, target
      return new KDNotificationView
        title : "It's not allowed connect this two joint."

    items = parseItems source, target
    return  if Object.keys(items).length < 2
    {domain, machine, rule, extra} = items

    return  if rule or extra
      new KDNotificationView
        title : "Assigning #{if rule then 'rules' else 'resources'} will be available soon."

    if domain and machine and not KD.checkFlag 'nostradamus'
      if domain.dia.getData().domain.hostnameAlias.length > 0
        return new KDNotificationView
          title : "A domain name can only be bound to one VM."

    # @addFakeConnection {
    #   source, target,
    #   options : {
    #     lineColor  : "#cdcdcd"
    #     lineDashes : [5]
    #   }
    # }

    if domain and machine
      jDomain = domain.dia.getData().domain # JDomain
      vmName  = machine.dia.getData().title # JVM.hostnameAlias
      jDomain.bindVM hostnameAlias: vmName, (err)=>
        return  if KD.showError err
        jDomain.hostnameAlias.push vmName
        createConnection()
    else if domain and rule
      createConnection()
    else if machine and extra
      createConnection()

  updateConnections:->

    for _mkey, machine of @boxes.machines.dias
      for _dkey, domain of @boxes.domains.dias
        if domain.getData().aliases and machine.getData().title in domain.getData().aliases
          @connect {dia : domain , joint : 'right'}, \
                   {dia : machine, joint : 'left' }, yes
        for _rkey, rule of @boxes.rules.dias
          if rule.getData().title is "Allow All"
            @connect {dia : rule,   joint : 'right'}, \
                     {dia : domain, joint : 'left' }, yes

  createApproveModal:(items, action)->
    return unless KD.isLoggedIn()
      new KDNotificationView
        title : "You need to login to change domain settings."
    return new EnvironmentApprovalModal {action}, items

  whenItemsLoadedFor:do->
    # poor man's when/promise implementation ~ GG
    (containers, callback)->
      counter = containers.length
      containers.forEach (container)->
        container.once "DataLoaded", ->
          if counter is 1 then do callback
          counter--
        container.loadItems()

  addContainer:(container, pos)->
    pos ?= x: 10 + @containers.length * 260, y: 0
    super container, pos

    {name} = container.constructor
    label  = containerMap[name] or name
    container._initialPosition = pos
    @boxes[label] = container

  parseItems = (source, target)->
    items = {}
    for item in [source, target]
      items[itemMap[item.dia.constructor.name]] = item
    return items

  type = (item)->
    itemMap[item.dia.constructor.name] or null

  viewAppended:->
    super

    # @addSubView @slider = new KDSliderBarView
    #   cssClass   : 'zoom-slider'
    #   minValue   : 0.3
    #   maxValue   : 1.0
    #   interval   : 0.1
    #   width      : 120
    #   snap       : no
    #   snapOnDrag : no
    #   drawBar    : yes
    #   showLabels : no
    #   handles    : [1]

    # handle   = @slider.handles.first

    # @addSubView zoomControls = new KDCustomHTMLView
    #   cssClass   : "zoom-controls"

    # zoomControls.addSubView zoomOut = new KDCustomHTMLView
    #   tagName    : "a"
    #   cssClass   : "zoom-control zoomout"
    #   partial    : "-"
    #   click      : -> handle.setValue handle.value-0.1

    # zoomControls.addSubView zoomIn = new KDCustomHTMLView
    #   tagName    : "a"
    #   cssClass   : "zoom-control zoomin"
    #   partial    : "+"
    #   click      : -> handle.setValue handle.value+0.1

    # @slider.on 'ValueIsChanging', (value)=>
    #   do _.throttle => @setScale value

    # @slider.on 'ValueChanged', (handle)=>
    #   @appStorage.setValue 'zoomLevel', handle.value

    # @addSubView resetView = new KDButtonView
    #   cssClass   : "reset-view"
    #   title      : "Reset layout"
    #   icon       : yes
    #   callback   : @bound 'resetLayout'

    # @appStorage.ready =>
    #   zoomLevel = @appStorage.getValue 'zoomLevel'
    #   @slider.setValue zoomLevel  if zoomLevel

  # resetLayout:->
  #   box.resetPosition()  for _key, box of @boxes
  #   @slider.setValue 1

class EnvironmentApprovalModal extends KDModalView

  getContentFor = (items, action)->
    content     = 'God knows.'

    titles = {}
    for title in ['domain', 'machine', 'rule', 'extra']
      titles[title] = items[title].dia.getData().title  if items[title]

    if action is 'create'

      if titles.domain? and titles.machine?
        content = """Do you want to assign <b>#{titles.domain}</b>
                     to <b>#{titles.machine}</b> machine?"""
      else if titles.domain? and titles.rule?
        content = """Do you want to enable <b>#{titles.rule}</b> rule
                     for <b>#{titles.domain}</b> domain?"""
      else if titles.machine? and titles.extra?
        content = """Do you want to add <b>#{titles.extra}</b>
                     to <b>#{titles.machine}</b> machine?"""

    else if action is 'delete'

      if titles.domain? and titles.machine?
        content = """Do you want to remove <b>#{titles.domain}</b>
                     domain from <b>#{titles.machine}</b> machine?"""
      else if titles.domain? and titles.rule?
        content = """Do you want to disable <b>#{titles.rule}</b> rule
                     for <b>#{titles.domain}</b> domain?"""
      else if titles.machine? and titles.extra?
        content = """Do you want to remove <b>#{titles.extra}</b>
                     from <b>#{titles.machine}</b> machine?"""

    return "<div class='modalformline'><p>#{content}</p></div>"

  constructor:(options={}, data)->

    options.title       or= "Are you sure?"
    options.overlay      ?= yes
    options.overlayClick ?= no
    options.buttons       =
      Yes                 :
        loader            :
          color           : "#444444"
          diameter        : 12
        cssClass          : if options.action is 'delete' \
                            then "modal-clean-red" else "modal-clean-green"
        callback          : =>
          @buttons.Yes.showLoader()
          @emit 'Approved'
      Cancel              :
        cssClass          : "modal-cancel"
        callback          : =>
          @emit 'Cancelled'
          @cancel()

    options.content = getContentFor data, options.action

    super options, data
