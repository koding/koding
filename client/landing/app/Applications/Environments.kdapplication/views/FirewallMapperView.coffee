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

    @ruleListController = new KDListViewController
      itemClass : FirewallRuleListItemView

    @actionListController = new FirewallActionListController

    @ruleListController.showLazyLoader()
    @actionListController.showLazyLoader()

    domain.fetchProxyRules (err, response)=>
      if err
        @ruleListController.hideLazyLoader()
        @actionListController.hideLazyLoader()
        if err is "not found"
          notifyMsg = "You don't have any rules set for this domain."
        else
          notifyMsg = "An error occured while fetching the rules. Please try again."
        return new KDNotificationView
          title : notifyMsg
          type  : "top"


      @iniateControllerListItems domain, response

    @fwRuleFormView = new FirewallRuleFormView {delegate:this}, {domain:domain}

    @addSubView @fwRuleFormView

    @addSubView @ruleListView = new KDCustomHTMLView
      partial  : "<h3>Rule List for #{domain.domain}</h3>"
      cssClass : 'rule-list-view'

    @addSubView @actionListView = new KDCustomHTMLView
      partial  : "<h3>Action List for #{domain.domain}</h3>"
      cssClass : "action-list-view"

    @ruleListView.addSubView @ruleListController.getView()

    @actionListScrollView = new KDScrollView
      cssClass : 'fw-al-sw'

    @actionListView.addSubView @actionListScrollView
    @actionListView.addSubView new KDButtonView
      title    : "Update Action Order"
      callback : => @updateActionOrders domain

    @actionListScrollView.addSubView @actionListController.getView()

    @on "newRuleCreated", (item)=>
      @ruleListController.addItem item

    # this event is on rule list controller because 
    # both allow & deny buttons live on FirewallRuleListItemView.
    @ruleListController.getListView().on "behaviorCreated", (item)=>
      @actionListController.addItem item

  iniateControllerListItems:(domain, response)->
    ruleKeys         = Object.keys(response.rules)
    actionKeys       = Object.keys(response.RuleList)
    responseRules    = response.rules
    responseRuleList = response.RuleList
    ruleList         = []
    actionList       = []

    for key in ruleKeys
      ruleList.push 
        domainName : domain.domain
        ruleName   : responseRules[key].Name
        match      : responseRules[key].Match
        type       : responseRules[key].Type
    
    for key in actionKeys
      actionList.push
        domainName : domain.domain
        ruleName   : responseRuleList[key].RuleName
        action     : responseRuleList[key].Action

    @ruleListController.instantiateListItems ruleList
    @ruleListController.hideLazyLoader()
    @actionListController.instantiateListItems actionList
    @actionListController.hideLazyLoader()

  updateActionOrders:(domain)->
    for item, index in @actionListController.itemsOrdered
      data = item.getData()
      domain.updateRuleBehavior
        ruleName   : data.ruleName
        behaviorInfo :
          enabled : "yes"
          action  : data.action
          index   : "#{index}"
      , (err, response)=>
        return console.log err if err?


class FirewallRuleListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'fw-rl-view'
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
    <div class="fw-li-view">
      <div class="fl fw-lookup-icon"></div>
      <div class="fl fw-li-rule">{{ #(match) }}</div>
      <div class="fr fw-li-buttons">
        {{> @allowButton }}
        {{> @denyButton }}
        {{> @deleteButton }}
      </div>
    </div>
    """


class FirewallActionListItemView extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = 'fw-al-view'
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
      <div class="fr fw-li-buttons">
        {{> @actionButton }}
        {{> @deleteButton }}
      </div>
    </div>
    """


class FirewallRuleFormView extends KDCustomHTMLView

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
        domainName:domainName
        ruleName:response.Name
        match:response.Match


  viewAppended:->
    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    ###
    <div class="fl">
      <label for="rulename" class="">Rule Name:</label>
      {{> @ruleNameInput }}
    </div>
    ###
    """
    <div class="fl">
      <label for="rule">Rule:</label>
      {{> @ruleInput }}
      {{> @addButton }}
    </div>
    
    <div class="clearfix"></div>
    """