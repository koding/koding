kd                     = require 'kd'
JView                  = require 'app/jview'
actions                = require 'app/flux/environment/actions'
isKoding               = require 'app/util/isKoding'
showError              = require 'app/util/showError'
KodingSwitch           = require 'app/commonviews/kodingswitch'
isTeamReactSide        = require 'app/util/isTeamReactSide'
MachineSettingsModal   = require '../providers/machinesettingsmodal'
ComputeErrorUsageModal = require '../providers/computeerrorusagemodal'


module.exports = class MachinesListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'machines-item clearfix', options.cssClass
    super options, data

    delegate = @getDelegate()
    { alwaysOn, slug, label } = machine = @getData()

    isManaged = machine.isManaged()

    @labelLink      = new kd.CustomHTMLView
      cssClass      : 'label-link'
      tagName       : 'span'
      partial       : label
      click         : ->
        kd.singletons.router.handleRoute "/IDE/#{slug}"

    alwaysOn = yes  if isManaged

    @alwaysOnToggle = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : alwaysOn
      disabled      : isManaged
      callback      : @bound 'handleAlwaysOnStateChanged'

    @settingsLink   = new kd.CustomHTMLView
      cssClass      : 'settings-link'
      partial       : 'settings'
      tagName       : 'span'
      click         : -> new MachineSettingsModal {}, machine

    # more to come like os, version etc.
    @vminfo =
      instance_type : machine.jMachine.meta?.instance_type or ''

    @createSidebarToggle()


  createSidebarToggle: ->

    return  if isKoding()

    machine = @getData()

    { computeController } = kd.singletons

    stack = computeController.findStackFromMachineId machine._id
    defaultValue = stack.config?.sidebar?[machine.uid]?.visibility
    defaultValue ?= on

    @sidebarToggle  = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : defaultValue
      callback      : @bound 'updateSidebarVisibility'


  handleAlwaysOnStateChanged: (state) ->

    { computeController } = kd.singletons

    machine = @getData()

    computeController.fetchUserPlan (plan) =>

      computeController.setAlwaysOn machine, state, (err) =>

        return  unless err

        if err.name is 'UsageLimitReached' and plan isnt 'hobbyist'
          kd.utils.defer => new ComputeErrorUsageModal { plan }
        else
          showError err

        @alwaysOnToggle.setOff no


  updateSidebarVisibility: (state) ->

    machine = @getData()

    { computeController } = kd.singletons

    stack   = computeController.findStackFromMachineId machine._id
    config  = stack.config ?= {}

    config.sidebar ?= {}
    config.sidebar[machine.uid] = { visibility: state }

    stack.modify { config }

    actions.loadStacks yes  if isTeamReactSide()


  pistachio: ->
    data = @getData()
    { provider } = data

    if provider is 'managed'
      provider = data.jMachine.meta.managedProvider or 'UnknownProvider'

    pData = PROVIDERS[provider]
    logo  = pData.logo or provider.toLowerCase()
    url   = pData.url

    logoImg = """
      <img class="logo #{provider}" src="/a/images/providers/#{logo}.png" />
    """

    # If the url has text, make the logoImg into a link
    logoImg = "<a href='#{url}' target='_blank'>#{logoImg}</a>"  if url

    """
      <div>
        {{> @labelLink}}
      </div>
      <div>
        #{logoImg}
      </div>
      <div>
        <span>VM{{> @settingsLink}}</span>
        <span>#{@vminfo.instance_type}</span>
      </div>
      <div>
        <span>UBUNTU</span>
        <span>14.2</span>
      </div>
      <div>
        {{> @alwaysOnToggle}}
      </div>
      #{unless isKoding() then '<div>{{> @sidebarToggle}}</div>' else ''}
    """

  PROVIDERS         =
    Azure           : url: 'https://azure.microsoft.com/en-us'
    HPCloud         : url: 'http://www.hpcloud.com'
    Joyent          : url: 'https://www.joyent.com/'
    SoftLayer       : url: 'http://www.softlayer.com'
    Rackspace       : url: 'http://www.rackspace.com'
    GoogleCloud     : url: 'https://cloud.google.com'
    DigitalOcean    : url: 'https://www.digitalocean.com'
    AWS             : url: 'http://aws.amazon.com'
    UnknownProvider : {}

    # handle `jMachine.provider` field.
    aws             : url: 'http://aws.amazon.com'
    koding          : url: 'http://aws.amazon.com', logo: 'aws'
    softlayer       : url: 'http://softlayer.com',  logo: 'softlayer'
