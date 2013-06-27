class FirewallRuleListItemView extends KDListItemView

  constructor:(options={}, data)->
    options = $.extend
      type     : 'rules'
      tagName  : 'tr'
    , options

    super options, data

    @actionButton = new KDButtonView
      title    : if data.action is "deny" then "Allow" else "Deny"
      callback : =>
        @updateProxyRule()

    @deleteButton = new KDButtonView
      title    : "Delete"
      callback : =>
        @deleteProxyRule()

    @on 'DragInAction', _.throttle (x, y)->
      if y isnt 0 and @_dragStarted
        @setClass 'ondrag'
    , 300

    @on 'DragFinished', (event)->

      @unsetClass 'ondrag'
      @_dragStarted = no

      height = $(event.target).closest('.kdlistitemview').height() or 33
      distance = Math.round(@dragState.position.relative.y / height)

      unless distance is 0
        itemIndex = @getDelegate().getItemIndex this
        newIndex  = itemIndex + distance
        @getDelegate().emit 'moveToIndexRequested', this, newIndex

      @setEmptyDragState yes

    @setDraggable
      handle : @
      axis   : "y"

  updateProxyRule:->
    data = @getData()
    delegate = @getDelegate()
    newAction = @actionButton.getOptions().title.toLowerCase()
    futureAction = if newAction is 'deny' then 'allow' else 'deny'
    data.action = newAction

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)=>
      domain.updateProxyRule data, (err)=>
        return console.log err if err?
        @actionButton.setTitle futureAction.capitalize()
        delegate.emit 'ruleActionChanged'

  deleteProxyRule:->
    data = @getData()
    delegate = @getDelegate()

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)=>
      domain.deleteProxyRule
        match   : data.match
        action  : data.action
        enabled : data.enabled
      , (err, result)=>
        return console.log err if err?
        new KDNotificationView {title:"Rule has been deleted from your firewall.", type:"top"}
        delegate.removeItem this
        delegate.emit "ruleDeleted"
        delegate.emit "ruleActionChanged"

  viewAppended:->
    @unsetClass 'kdivew'
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    {action, match} = @getData()
    ruleText = if action is "deny"
    then "Denying network connections from <strong>#{match}</strong>"
    else "Allowing network connections from <strong>#{match}</strong>"

    """
    <td class="action"><span class="fl #{action}-icon"></span></td>
    <td>#{ruleText}</td>
    <td>
      {{> @actionButton }}
      {{> @deleteButton }}
    </td>
    """

class EmptyFirewallRuleListItemView extends FirewallRuleListItemView

  pistachio:->
    """
    <td colspan="3">You don't have any rules for this domain.</td>
    """