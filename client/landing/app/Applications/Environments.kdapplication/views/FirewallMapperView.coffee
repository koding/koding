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

    @filterListController.showLazyLoader()
    @ruleListController.showLazyLoader()

    domain.fetchProxyFilters (err, response)=>
      if err
        @filterListController.hideLazyLoader()
        @ruleListController.hideLazyLoader()
        
        notifyMsg = if err is "not found"
        then "You don't have any filters set for this domain."
        else "An error occured while fetching the filters. Please try again."

        @actionOrdersButton.hide() if err is "not found"

        return new KDNotificationView
          title : notifyMsg
          type  : "top"


      @iniateControllerListItems domain, response

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

    @on "newRuleCreated", (item) => 
      @filterListController.addItem item

    # this event is on rule list controller because 
    # both allow & deny buttons live on FirewallfilterListItemView.
    @filterListController.getListView().on "behaviorCreated", (item) => 
      @ruleListController.addItem item

  iniateControllerListItems:(domain, response)->
    ###
    ruleKeys         = Object.keys(response.rules)
    actionKeys       = Object.keys(response.filterList)
    responseRules    = response.rules
    responsefilterList = response.filterList
    filterList         = []
    ruleList       = []

    for key in ruleKeys
      filterList.push 
        domainName : domain.domain
        ruleName   : responseRules[key].Name
        match      : responseRules[key].Match
        type       : responseRules[key].Type
    
    for key in actionKeys
      ruleList.push
        domainName : domain.domain
        ruleName   : responsefilterList[key].RuleName
        action     : responsefilterList[key].Action
    ###




    @filterListController.instantiateListItems filterList
    @filterListController.hideLazyLoader()
    @ruleListController.instantiateListItems ruleList
    @ruleListController.hideLazyLoader()

  updateActionOrders:(domain)->
    for item, index in @ruleListController.itemsOrdered
      data = item.getData()
      domain.updateRuleBehavior
        ruleName   : data.ruleName
        behaviorInfo :
          enabled : "yes"
          action  : data.action
          index   : "#{index}"
      , (err, response)=>
        return console.log err if err?


class FirewallFilterListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'fw-rl-view'
    options.type     = 'rules'
    super options, data

    @allowButton = new KDButtonView
      title    : "Allow"
      callback : => @createBehavior 'allow'

    @denyButton = new KDButtonView
      title    : "Deny"
      callback : => @createBehavior 'deny'

    @deleteButton = new KDButtonView
      title : "Delete"
      viewOptions:
        cssClass : 'delete-button'

  viewAppended:->
    @unsetClass 'kdview'
    @setTemplate @pistachio()
    @template.update()

  createBehavior:(behavior)->
    data = @getData()
    delegate = @getDelegate()

    KD.remote.api.JDomain.one {domainName:data.domainName}, (err, domain)->
      return console.log err if err
      domain.createRuleBehavior
        ruleName   : data.ruleName
        behaviorInfo :
          enabled : "yes"
          action  : behavior
          index   : "0"
      , (err, response)=>
        if not err
          delegate.emit "behaviorCreated", {domainName:data.domainName, ruleName:data.ruleName, action:behavior}

  pistachio:->
    """
    {div.fl.fw-li-rule{ #(match)}}
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
      <div class="fl">{{ #(ruleName) }}</div>
      <div class="fr buttons">
        {{> @actionButton }}
        {{> @deleteButton }}
      </div>
    </div>
    """


class FirewallFilterFormView extends KDCustomHTMLView

  constructor:(options={}, data)->
    options.cssClass = "rule-form-view"
    super options, data

    @ruleNameInput  = new KDInputView {tooltip: {title: "Enter a name for the rule.", placement:"bottom"}}
    @ruleInput      = new KDInputView
      tooltip : 
        title     : "You can enter IP, IP Range or a country name. (ie: 192.168.1.1/24 or China)"
        placement : "bottom"
    @ruleNameInput.unsetClass 'kdinput'
    @ruleInput.unsetClass 'kdinput'

    @addButton = new KDButtonView
      title    : "Add"
      callback : =>
        @updateDomainRules()

  updateDomainRules:->
    ruleType   = if @ruleInput.getValue().match /[0-9+]/ then "ip" else "country"
    ruleName   = @ruleNameInput.getValue()
    ruleMatch  = @ruleInput.getValue()
    domain     = @getData().domain
    domainName = domain.domain
    delegate   = @getDelegate()

    domain.createProxyRule {ruleInfo:{type:ruleType, match:ruleMatch}}, (err, response)->
      if err
        return new KDNotificationView 
          title : "An error occured while performing your action. Please try again."
          type  : "top"
      delegate.emit "newRuleCreated", 
        domainName : domainName
        ruleName   : response.Name
        match      : response.Match

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="fl">
      <label for="rulename" class="">Rule Name:</label>
      {{> @ruleNameInput }}
    </div>
    <div class="fl">
      <label for="rule">Rule:</label>
      {{> @ruleInput }}
      {{> @addButton }}
    </div>
    
    <div class="clearfix"></div>
    """