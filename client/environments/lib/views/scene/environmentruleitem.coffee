kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
AddFirewallRuleModal = require '../firewall/addfirewallrulemodal'
ColorSelection = require './colorselection'
DomainDeletionModal = require '../domains/domaindeletionmodal'
EnvironmentItem = require './environmentitem'
isGuest = require 'app/util/isGuest'
showError = require 'app/util/showError'
KodingSwitch = require 'app/commonviews/kodingswitch'
module.exports = class EnvironmentRuleItem extends EnvironmentItem

  constructor: (options = {}, data) ->

    options.cssClass           = 'rule'
    options.joints             = ['right']
    options.allowedConnections =
      EnvironmentDomainItem    : ['left']

    super options, data

    @setClass "disabled"  unless data.enabled

  contextMenuItems: ->
    colorSelection = new ColorSelection
      selectedColor : @getOption 'colorTag'

    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items          =
      customView4  : @createToggleMenu()
      Edit         :
        disabled   : isGuest()
        action     : 'edit'
      Delete       :
        disabled   : isGuest()
        action     : 'delete'
        separator  : yes
      customView   : colorSelection

    return items

  createToggleMenu: ->
    stateSwitch    = new KDCustomHTMLView
      cssClass     : "toggle-menu"

    stateSwitch.addSubView new KDCustomHTMLView
      tagName      : "span"
      partial      : "Enabled"

    stateSwitch.addSubView new KodingSwitch
      cssClass     : "tiny toggle-item"
      defaultValue : @getData()?.enabled ? yes
      callback     : @bound "setState"

    return stateSwitch

  setState: (state) ->
    data = @getData()
    data.update enabled: state, (err) =>
      return showError err  if err
      data.enabled = state
      @handleDataUpdate()

  cmedit: ->
    modal = new AddFirewallRuleModal {}, @getData()
    modal.once "RuleUpdated", @bound "handleDataUpdate"

  handleDataUpdate: (silently = no) ->
    @template.update()
    {enabled} = @getData()
    if enabled then @unsetClass "disabled" else @setClass "disabled"
    @emit "RuleDataUpdated"  unless silently

  confirmDestroy: ->
    data           = @getData()
    options        =
      deleteMesage : "<b>#{data.name}</b> has been removed."
      content      : "<div class='modalformline'>This will remove the rule <b>#{data.name}</b> permanently, there is no way back!</div>"

    deletionModal = new DomainDeletionModal options, @getData()
    deletionModal.on "domainRemoved", @bound "destroy"
