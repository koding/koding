kd                     = require 'kd'
JView                  = require 'app/jview'
showError              = require 'app/util/showError'
KodingSwitch           = require 'app/commonviews/kodingswitch'
MachineSettingsModal   = require '../providers/machinesettingsmodal'
ComputeErrorUsageModal = require '../providers/computeerrorusagemodal'


module.exports = class MachinesListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'machines-item clearfix', options.cssClass
    super options, data

    delegate = @getDelegate()
    { alwaysOn, slug, label } = machine = @getData()

    @labelLink      = new kd.CustomHTMLView
      cssClass      : 'label-link'
      tagName       : 'span'
      partial       : label
      click         : ->
        kd.singletons.router.handleRoute "/IDE/#{slug}"

    @alwaysOnToggle = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : alwaysOn
      callback      : @bound 'handleAlwaysOnStateChanged'

    # removed from the view since functionality isn't there - SY
    @sidebarToggle  = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : yes
      callback      : (state) -> console.log "sb >>", state

    @settingsLink   = new kd.CustomHTMLView
      cssClass      : 'settings-link'
      partial       : 'settings'
      tagName       : 'span'
      click         : -> new MachineSettingsModal {}, machine

    # more to come like os, version etc.
    @vminfo =
      instance_type : machine.jMachine.meta?.instance_type or ''


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


  pistachio: ->
    data = @getData()
    { provider } = data

    if provider is 'managed'
      provider = data.jMachine.meta.managedProvider

    pData = PROVIDERS[provider]
    logo  = pData.logo or provider.toLowerCase()
    url   = pData.url

    """
      <div>
        {{> @labelLink}}
      </div>
      <div>
        <a href="#{url}" target="_blank">
          <img class="logo #{provider}" src="/a/images/providers/#{logo}.png" />
        </a>
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
    """

  PROVIDERS      =
    Azure        : url: 'https://azure.microsoft.com/en-us'
    HPCloud      : url: 'http://www.hpcloud.com'
    Joyent       : url: 'https://www.joyent.com/'
    SoftLayer    : url: 'http://www.softlayer.com'
    Rackspace    : url: 'http://www.rackspace.com'
    GoogleCloud  : url: 'https://cloud.google.com'
    DigitalOcean : url: 'https://www.digitalocean.com'
    AWS          : url: 'http://aws.amazon.com'

    # handle `jMachine.provider` field.
    aws          : url: 'http://aws.amazon.com'
    koding       : url: 'http://aws.amazon.com', logo: 'aws'
