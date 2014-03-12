class StackView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-stack', options.cssClass

    super options, data

    @bindTransitionEnd()

  viewAppended:->

    {stack} = @getOptions()
    title   = stack.meta?.title
    number  = if stack.sid > 0 then "#{stack.sid}." else "default"
    group   = KD.getGroup().title
    title or= "Your #{number} stack on #{group}"

    @addSubView title = new KDView
      cssClass : 'stack-title'
      partial  : title

    @addSubView toggle = new KDButtonView
      title    : 'Hide details'
      cssClass : 'stack-toggle solid on clear'
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
      cssClass  : 'stack-context solid clear'
      style     : 'comment-menu'
      title     : ''
      iconOnly  : yes
      delegate  : this
      iconClass : "cog"
      callback  : (event)=>
        new JContextMenu
          cssClass    : 'environments'
          event       : event
          delegate    : this
          x           : context.getX() - 138
          y           : context.getY() + 40
          arrow       :
            placement : 'top'
            margin    : 150
        ,
          'Show stack recipe'  :
            callback           : @bound "dumpStack"
          'Clone this stack'   :
            callback           : =>
              @emit "CloneStackRequested", @getStackDump()
          'Create a new stack' :
            callback           : @bound "showCreateStackModal"

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene @getData().stack

    # Rules Container
    @rules = new EnvironmentRuleContainer
    @scene.addContainer @rules

    # Domains Container

    @domains = new EnvironmentDomainContainer { delegate: this }
    @scene.addContainer @domains
    @domains.on 'itemAdded', @lazyBound 'updateView', yes

    # VMs / Machines Container
    stackId = @getOptions().stack.getId?()
    @vms    = new EnvironmentMachineContainer { stackId }
    @scene.addContainer @vms

    KD.getSingleton("vmController").on 'VMListChanged', =>
      EnvironmentDataProvider.get (data) => @loadContainers data

    # Rules Container
    @extras = new EnvironmentExtraContainer
    @scene.addContainer @extras

    @loadContainers()

  loadContainers: (data)->

    env     = data or @getData()
    orphans = domains: [], vms: []
    {stack, isDefault} = @getOptions()

    # Add rules
    @rules.removeAllItems()
    @rules.addItem rule  for rule in env.rules

    # Add domains
    @domains.removeAllItems()
    for domain in env.domains
      if domain.stack is stack._id #or isDefault
        @domains.addDomain domain
      else
        orphans.domains.push domain

    # Add vms
    @vms.removeAllItems()
    for vm in env.vms
      if vm.stack is stack._id #or isDefault
      then @vms.addItem title:vm.alias
      else orphans.vms.push vm

    # log "orphans", orphans

    # Add extras
    @extras.removeAllItems()
    @extras.addItem extra  for extra in env.extras

    # log "ORPHANS", orphans

    @setHeight @getProperHeight()
    KD.utils.wait 300, =>
      @_inProgress = no
      @updateView yes

  dumpStack:->
    new KDModalView
      cssClass : 'recipe'
      title    : 'Stack recipe'
      overlay  : yes
      width    : 600
      content  : """
        <pre>
          #{@getStackDump yes}
        </pre>
      """

  getStackDump: (asYaml = no) ->
    {containers, connections} = @scene
    dump = {}

    for i, container of containers
      name = EnvironmentScene.containerMap[container.constructor.name]
      dump[name] = []
      for j, dia of container.dias
        dump[name].push \
          if name is 'domains'
            title   : dia.data.title
            aliases : dia.data.aliases
          else dia.data

    return if asYaml then jsyaml.dump dump else dump

  updateView:(dataUpdated = no)->

    @scene.updateConnections()  if dataUpdated

    if @getHeight() > 50
      @setHeight @getProperHeight()

    @scene.highlightLines()
    @scene.updateScene()

  getProperHeight:->
    (Math.max.apply null, \
      (box.diaCount() for box in @scene.containers)) * 45 + 170

  showCreateStackModal: ->
    modal                       = new KDModalViewWithForms
      title                     : "Create a new stack"
      cssClass                  : "create-stack"
      content                   : ""
      overlay                   : yes
      width                     : 720
      height                    : "auto"
      tabs                      :
        forms                   :
          CreateStackForm       :
            callback            : =>
              {title, slug}     = modal.modalTabs.forms.CreateStackForm.inputs
              meta              =
                title           : title.getValue()
                slug            : KD.utils.slugify slug.getValue()
              @emit "NewStackRequested", meta, modal
            buttons             :
              create            :
                title           : "Create"
                style           : "modal-clean-green"
                type            : "submit"
                loader          :
                  color         : '#eee'
                callback        : =>
                  form          = modal.modalTabs.forms.CreateStackForm
                  form.once "FormValidationFailed", =>
                    modal.modalTabs.forms.CreateStackForm.buttons.create.hideLoader()
              cancel            :
                title           : "Cancel"
                style           : "modal-cancel"
                callback        : -> modal.destroy()
            fields              :
              title             :
                label           : "Stack title"
                type            : "text"
                name            : "title"
                keyup           : =>
                  {title, slug} = modal.modalTabs.forms.CreateStackForm.inputs
                  slug.setValue KD.utils.slugify title.getValue()
                validate        :
                  rules         :
                    required    : yes
                  messages      :
                    required    : "Stack title cannot be blank."
              slug              :
                label           : "Domain prefix"
                type            : "text"
                name            : "slug"
                validate        :
                  rules         :
                    required    : yes
                  messages      :
                    required    : "Domain prefix cannot be blank"
