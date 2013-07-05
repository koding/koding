class FirewallFilterListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'filter-item'
    options.type     = 'filters'
    options.tagName  = 'tr'
    super options, data

    @allowButton = new KDButtonView
      title    : "Allow"
      callback : => @createRule 'allow'

    @denyButton = new KDButtonView
      title    : "Deny"
      callback : => @createRule 'deny'

    @deleteButton = new KDButtonView
      title       : "Delete"
      viewOptions :
        cssClass  : 'delete-button'
      callback    : => @deleteFilter()

  viewAppended:->
    @unsetClass 'kdview'
    @setTemplate @pistachio()
    @template.update()

    data = @getData()
    if data and data.ruleAction in ['allow', 'deny']
      @hide()

  createRule:(behavior)->
    data         = @getData()
    delegate     = @getDelegate()
    delegateData = delegate.getData()
    domainName   = delegateData.domain.domain

    KD.remote.api.JDomain.one {domainName}, (err, domain)=>
      return console.log err if err

      domain.fetchProxyRules (err, rules)=>

        proxyRuleMatches = if rules then (rule.match for rule in rules) else []

        if proxyRuleMatches.indexOf(data.match) is -1
          params =
            domainName : domain.domain
            action     : behavior
            match      : data.match

          domain.createProxyRule params, (err, rule)=>
            return console.log err if err

            ruleObj =
              domainName : data.domainName
              action     : rule.action
              match      : rule.match
              enabled    : rule.enabled

            delegate.emit "newRuleCreated", ruleObj
            @hide()

  deleteFilter:->
    data = @getData()

    KD.remote.api.JProxyFilter.remove {_id:data.getId()}, (err)=>
      unless err
        @getDelegate().emit "filterDeleted", this

  pistachio:->
    {name, match} = @getData()
    """
    <td class="filter-name">
      #{name}
    </td>
    <td class="filter-match">#{match}</td>
    <td class="actions">
      {{> @allowButton }}
      {{> @denyButton }}
      {{> @deleteButton }}
    </td>
    """

class EmptyFirewallFilterListItemView extends FirewallFilterListItemView

  pistachio:->
    """
    <td colspan="3">You don't have any filters.</td>
    """