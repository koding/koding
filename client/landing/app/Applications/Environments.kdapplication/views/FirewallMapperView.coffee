class FirewallMapperView extends KDView

  constructor:(options={}, data) ->
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

    @addSubView new KDCustomHTMLView
      partial: 'Select a domain to continue.'

  updateViewContent:->
    domain = @getData().domain

    @destroySubViews()

    @filterListController = new KDListViewController
      itemClass : FirewallFilterListItemView

    @ruleListController = new FirewallRuleListController

    KD.remote.api.JProxyFilter.fetchFiltersByContext (err, filters)=>
      if err

        notifyMsg = if err is "not found"
        then "You don't have any filters set for this domain."
        else "An error occured while fetching the filters. Please try again."

        @actionOrdersButton.hide() if err is "not found"
        return new KDNotificationView
          title : notifyMsg
          type  : "top"

      for filter in filters
        filter.domainName = domain.domain

      @filterListController.instantiateListItems filters

    KD.remote.api.JProxyRestriction.fetchRestrictionByDomain domain.domain, (err, restriction)=>
      unless err
        @ruleListController.instantiateListItems restriction.ruleList

    @fwRuleFormView = new FirewallFilterFormView delegate:this, {domain}

    @addSubView @fwRuleFormView

    @addSubView @filterListView = new KDCustomHTMLView
      partial  : "<h3>Your Filter List</h3>"
      cssClass : 'rule-list-view'

    @addSubView @ruleListView = new KDCustomHTMLView
      partial  : "<h3>Rule List for #{domain.domain}</h3>"
      cssClass : "action-list-view"

    @filterListView.addSubView @filterListController.getView()

    @ruleListScrollView = new KDScrollView
      cssClass : 'fw-al-sw'

    @ruleListView.addSubView @ruleListScrollView
    @ruleListView.addSubView @actionOrdersButton = new KDButtonView
      title    : "Update Action Order"
      callback : => @updateActionOrders domain

    @ruleListScrollView.addSubView @ruleListController.getView()

    @on "newFilterCreated", (item) => 
      @filterListController.addItem item

    # this event is on rule list controller because 
    # both allow & deny buttons live on FirewallfilterListItemView.
    @ruleListController.getListView().on "newRuleCreated", (item) => 
      @ruleListController.addItem item

  updateActionOrders:(domain)->
    newRulesList = (item.getData() for item in @ruleListController.itemsOrdered)
    domain.updateRuleOrders newRulesList, (err, response)->
      return console.log err if err?


class FirewallFilterListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'fw-rl-view'
    options.type     = 'rules'
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

  createRule:(behavior)->
    data = @getData()
    delegate = @getDelegate()

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)->
      return console.log err if err

      params = 
        domainName: domain.domain
        action    : behavior
        match     : data.match
      
      domain.createProxyRule params, (err, rule)->
        return console.log err if err
        delegate.emit "newRuleCreated", {domainName:data.domainName, ruleName:data.ruleName, action:behavior}

  deleteFilter:->
    data = @getData()
    KD.remote.api.JProxyFilter.remove {_id:data.getId()}, (err)=>
      unless err then @destroy()

  pistachio:->
    """
    <div class="fl fw-li-rule"> {{ #(name) }} - {{ #(match) }}</div>
    <div class="fr buttons">
      {{> @allowButton }}
      {{> @denyButton }}
      {{> @deleteButton }}
    </div>
    <div class="clearfix"></div>
    """


class FirewallRuleListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'fw-al-view'
    options.type     = 'actions'
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

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)=>
      domain.updateRuleBehavior
        ruleName   : data.ruleName
        behaviorInfo :
          enabled : "yes"
          action  : newAction
          index   : "0"
      , (err, response)=>
        return console.log err if err?
        @$().find("div.fw-li-view").removeClass(futureAction).addClass(newAction)
        @actionButton.setTitle futureAction


  deleteProxyRule:->
    data = @getData()

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)=>
      domain.deleteRuleBehavior {ruleName:data.ruleName}, (err, result)=>
        return console.log err if err?
        new KDNotificationView {title:"Action has been deleted from your firewall.", type:"top"}
        @destroy()


  viewAppended:->
    @unsetClass 'kdivew'
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="fw-li-view #{@getData().action}">
      <div class="fl">{{ #(match) }}</div>
      <div class="fr buttons">
        {{> @actionButton }}
        {{> @deleteButton }}
      </div>
    </div>
    """


class FirewallFilterFormView extends KDCustomHTMLView

  constructor:(options={}, data)->
    options.cssClass = "filter-form-view"
    super options, data

    @filterNameInput  = new KDInputView {tooltip: {title: "Enter a name for the filter.", placement:"bottom"}}
    @filterInput      = new KDInputView
      tooltip : 
        title     : "You can enter IP, IP Range or a country name. (ie: 192.168.1.1/24 or China)"
        placement : "bottom"
    @filterNameInput.unsetClass 'kdinput'
    @filterInput.unsetClass 'kdinput'

    @addButton = new KDButtonView
      title    : "Add"
      callback : =>
        @updateFilters()

  updateFilters:->
    filterType  = if @filterInput.getValue().match /[0-9+]/ then "ip" else "country"
    filterName  = @filterNameInput.getValue()
    filterMatch = @filterInput.getValue()
    delegate    = @getDelegate()

    KD.remote.api.JProxyFilter.createFilter
      name  : filterName
      type  : filterType
      match : filterMatch
    , (err, filter)->
      console.log err, filter
      unless err 
        delegate.emit "newFilterCreated", {name:filterName, match:filterMatch}

      return new KDNotificationView 
        title : "An error occured while performing your action. Please try again."
        type  : "top"
      

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <div class="fl">
      <label for="filtername" class="">Filter Name:</label>
      {{> @filterNameInput }}
    </div>
    <div class="fl">
      <label for="filter">Match:</label>
      {{> @filterInput }}
      {{> @addButton }}
    </div>
    
    <div class="clearfix"></div>
    """