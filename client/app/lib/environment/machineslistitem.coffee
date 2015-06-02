kd           = require 'kd'
JView        = require 'app/jview'
KodingSwitch = require 'app/commonviews/kodingswitch'


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
      callback      : (state) -> console.log "ao >>", state

    @sidebarToggle  = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : yes
      callback      : (state) -> console.log "sb >>", state

  pistachio: ->
    """
      <div>
        {{> @labelLink}}
        {{#(provider)}}
      </div>
      <div>
        <span>VM</span>
        {{#(jMachine.meta.instance_type)}}
      </div>
      <div>
        <span>UBUNTU</span>
        <span>14.2</span>
      </div>
      <div>
        {{> @alwaysOnToggle}}
      </div>
    """
