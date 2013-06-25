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
        @$().find("div.fw-li-view").removeClass(futureAction).addClass(newAction)
        @actionButton.setTitle futureAction.capitalize()


  deleteProxyRule:->
    data = @getData()

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)=>
      domain.deleteProxyRule {match:data.match}, (err, result)=>
        return console.log err if err?
        new KDNotificationView {title:"Rule has been deleted from your firewall.", type:"top"}
        @destroy()


  viewAppended:->
    @unsetClass 'kdivew'
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    {action, match} = @getData()
    ruleText = if action is "deny"
    then "Denying network connections from #{match}"
    else "Allowing network connections from #{match}"

    """
    <td class="action"><span class="fl #{action}-icon"></span></td>
    <td>#{ruleText}</td>
    <td>
      {{> @actionButton }}
      {{> @deleteButton }}
    </td>
    """