class StackView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-stack', options.cssClass

    super options, data

    @bindTransitionEnd()
    @stack = @getData()


  viewAppended:->

    @createHeaderElements()

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene {}, @stack

    # Rules Container
    # @rules = new EnvironmentRuleContainer {}, @stack
    # @scene.addContainer @rules
    # @rules.on "itemAdded", @lazyBound "updateView", yes

    # Domains Container
    @domains = new EnvironmentDomainContainer {}, @stack
    @scene.addContainer @domains
    @domains.on 'itemAdded',   @lazyBound 'updateView', yes
    @domains.on 'itemRemoved', @lazyBound 'updateView', yes

    # VMs / Machines Container
    @machines = new EnvironmentMachineContainer {}, @stack
    @scene.addContainer @machines
    @machines.on 'itemAdded',   @lazyBound 'updateView', yes
    @machines.on 'itemRemoved', @lazyBound 'updateView', yes

    # Extras Container
    # @extras = new EnvironmentExtraContainer {}, @stack
    # @scene.addContainer @extras
    # @extras.on 'itemAdded', @lazyBound 'updateView', yes

    @loadContainers()
    @emit "ready", this

  loadContainers: (data)->

    # Add rules
    # if @stack.rules?
    #   @rules.removeAllItems()
    #   @rules.addItem rule        for rule in @stack.rules

    # Add domains
    if @stack.domains?
      @domains.removeAllItems()
      @domains.addDomain domain  for domain in @stack.domains

    # Add machines
    if @stack.machines?
      @machines.removeAllItems()
      @machines.addItem machine  for machine in @stack.machines

    # Add extras
    # if @stack.extras?
    #   @extras.removeAllItems()
    #   @extras.addItem extra      for extra in @stack.extras

    @setHeight @getProperHeight()

    KD.utils.wait 300, =>
      @_inProgress = no
      @updateView yes


  deleteStack: ->

    # REMOVE ME BEFORE PUBLISH ~ GG !!!
    # ----
    @stack.delete (err, res) =>
      return KD.showError err  if err
      KD.utils.defer @bound 'destroy'

    return
    # -----

    stackTitle = @stack.title or ""
    stackSlug  = "confirm"

    modal      = new VmDangerModalView
      name     : stackTitle
      action   : "DELETE MY STACK"
      title    : "Delete your #{stackTitle} stack"
      width    : 650
      content  : """
          <div class='modalformline'>
            <p><strong>CAUTION! </strong>This will destroy your #{stackTitle} stack including</strong>
            all VMs and domains inside this stack. You will also lose all your data in your VMs. This action <strong>CANNOT</strong> be undone.</p><br><p>
            Please enter <strong>#{stackSlug}</strong> into the field below to continue: </p>
          </div>
        """
      callback : =>

        modal.destroy()
        @stack.delete (err, res) =>
          return KD.showError err  if err
          @destroy()

    , stackSlug


  ### Stack Config Helpers ###

  ###*
   * creates a new EditorModal
   * @return {EditorModal} stack config editor
  ###
  createConfigEditor: ->

    # FIXME we need to use key/value ui for this ~ GG

    content = ""
    for key, value of @stack.config or {}
      content += "#{key}=#{value}\n"

    new EditorModal
      editor              :
        title             : "Stack Config Editor <span>(experimental)</span>"
        content           : content
        saveMessage       : "Stack config saved."
        saveFailedMessage : "Couldn't save your config"
        saveCallback      : (config, modal)=>

          newConfig = {}
          for line in config.split '\n'
            [key, value]   = line.split '='
            newConfig[key] = value  if key? and value?

          @stack.modify config: newConfig, (err, res) =>
            modal.emit if err then "SaveFailed" else "Saved"
            @stack.config = newConfig  unless err

  ### Stack Dump Helpers ###

  ###*
   * helper to dump stack information
   * inside of a {new EditorModal}
  ###
  dumpStack:->

    stackRecipe  = @getStackDump yes

    editorModal  = new EditorModal
      removeOnOverlayClick : yes
      cssClass   : "recipe-editor"
      editor     :
        title    : "Stack recipe"
        content  : stackRecipe
        readOnly : yes
        buttons  : [
          {
            title    : "Publish"
            cssClass : "solid compact green disabled"
            tooltip  :
              title  : "Publishing to App-Store is currently under development. This will allow you to share your stacks."
          }
          {
            title    : "Close"
            cssClass : "solid compact gray"
            callback : -> editorModal.destroy()
          }
        ]

  ###*
   * walk through stacks and create a dump
   * @param  {boolean} asYaml = no [returns dump as yAML formatted if true]
   * @return {object} JSON or yAML dump of stack
  ###
  getStackDump: (asYaml = no) ->

    {containers, connections} = @scene
    dump = {}

    dump.config = "[...]"  if @stack.config

    for i, container of containers
      name = EnvironmentScene.containerMap[container.constructor.name]
      dump[name] = []
      for j, dia of container.dias
        dump[name].push \
          if name is 'domains'
            title    : dia.data.title
            machines : dia.data.machines
          else if name is 'machines'
            obj     =
              provider : dia.data.provider
              meta     : dia.data.meta
            if dia.data.initScript
              obj.initScript = "[...]"
            obj
          # else if name is 'rules'
          #   title   : dia.data.name
          #   rules   : dia.data.rules
          else dia.data

    return if asYaml then jsyaml.dump dump else dump


  ### UI Helpers ###


  getProperHeight:->
    (Math.max.apply null,                     \
      (box.diaCount() * (box.itemHeight + 10) \
        for box in @scene.containers))  + 170


  getMenuItems:->
    this_ = this
    items =
      'Show stack recipe'  :
        callback           : @bound "dumpStack"
      'Clone this stack'   :
        callback           : =>
          stackDump        = @getStackDump()
          stackDump.config = @stack.config or ""
          @emit "CloneStackRequested", stackDump
      'Delete stack'       :
        callback           : ->
          @destroy(); this_.deleteStack()

    return items


  createHeaderElements:->

    group = KD.getGroup().title
    title = "#{@stack.title or 'a'} on #{group}"

    @addSubView title = new KDView
      cssClass : 'stack-title'
      partial  : title

    @addSubView toggle = new KDButtonView
      title    : 'Hide details'
      cssClass : 'stack-toggle solid on clear stack-button'
      iconOnly : yes
      iconClass: 'toggle'
      callback : =>
        if @getHeight() <= 50
          @setHeight @getProperHeight()
          toggle.setClass 'on'
        else
          toggle.unsetClass 'on'
          @setHeight 48
        KD.utils.wait 300, @bound 'updateView'

    @addSubView context = new KDButtonView
      cssClass  : 'stack-context solid clear stack-button'
      style     : 'comment-menu'
      title     : ''
      iconOnly  : yes
      delegate  : this
      iconClass : "cog"
      callback  : (event)=>
        new KDContextMenu
          cssClass    : 'environments'
          event       : event
          delegate    : this
          x           : context.getX() - 138
          y           : context.getY() + 40
          arrow       :
            placement : 'top'
            margin    : 150
        , @getMenuItems()

    @addSubView configEditor = new KDButtonView
      cssClass  : "stack-editor solid clear stack-button"
      iconOnly  : yes
      iconClass : "editor"
      callback  : @bound "createConfigEditor"


  updateView:(dataUpdated = no)->

    @scene.updateConnections()  if dataUpdated

    @setHeight @getProperHeight()  if @getHeight() > 50

    @scene.highlightLines()
    @scene.updateScene()
