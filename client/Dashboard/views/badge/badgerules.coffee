class BadgeRules extends JView
  constructor:(options = {}, data) ->

    @badgeRulesListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-rules"
        itemClass         : BadgeRuleItem

    @badgeListView = @badgeRulesListController.getListView()

    #@badgeRulesListController.addItem {}

    @addRule          = new KDButtonView
      name            : 'addrule'
      style           : 'add-new-rule'
      title           : '+'
      callback        : =>
        @badgeRulesListController.addItem {}

    @doneButton       = new KDButtonView
      name            : 'listdone'
      style           : 'rule-set-done'
      title           : 'done'
      callback        : =>
        @createUserSelector()
        @giveBadgeButton.show()

    @filteredUsersController = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "users"
        cssClass             : "user-list"
        itemClass            : BadgeUsersItem

    @giveBadgeButton  = new KDButtonView
      name            : 'createbadge'
      style           : 'create-badge-button'
      title           : 'Create'
      type            : "submit"

    @usersInput       = new KDInputView
      type            : "hidden"
      name            : "ids"

    @rule             = new KDInputView
      type            : "hidden"
      name            : "rule"

    @userList = @filteredUsersController.getView()

    @badgeListView.on "RemoveRuleFromList", (item)=>
      @badgeRulesListController.removeItem item

    @giveBadgeButton.hide()

    super options, data

    {@badge} = @getOptions()
    if @badge
      @updateRulesList()

  createUserSelector: (limit, skip)->
    selector   = {}
    rules      = ""
    ruleItems  = @badgeRulesListController.getItemsOrdered()
    for ruleItem, key in ruleItems
      property = ruleItem.propertySelect.getValue()
      tmpAct   = ruleItem.propertyAction.getValue()
      propVal  = ruleItem.propertyVal.getValue()

      operArr  = {}

      if tmpAct is "<" then action = "$lt" else action = "$gt"

      operArr[action]    = propVal
      selector[property] = operArr
      rules += property + tmpAct + propVal
      rules += "+" if key < ruleItems.length-1

    @rule.setValue rules
    KD.remote.api.JAccount.someWithRelationship selector, {}, (err,users) =>
      return err if err
      @usersInput.setValue (user._id for user in users)
      @filteredUsersController.removeAllItems()
      @filteredUsersController.instantiateListItems users

  updateRulesList:->
    ruleArray = @badge.rule.split "+"
    for rule in ruleArray
      decoded  = Encoder.htmlDecode rule
      actionPos = decoded.search /[\<\>\=]/
      action    = decoded.substr actionPos, 1
      property  = decoded.substr 0,actionPos
      propVal   = decoded.substr actionPos+1
      @badgeRulesListController.addItem {property,action,propVal}

  pistachio:->
    """
    {{> @addRule}}
    {{> @doneButton}}
    {{> @badgeListView}}
    {{> @userList}}
    {{> @giveBadgeButton}}
    {{> @usersInput}}
    {{> @rule}}
    """

class BadgeUsersItem extends KDListItemView
  constructor: (options ={}, data)->
    super options, data
    @account = @getData()

    @avatar    = new AvatarImage
      origin   : @account.profile.nickname
      size     :
        width  : 40

  viewAppended: JView::viewAppended

  pistachio:->
    nickname = @account.profile.nickname
    """
     {{> @avatar}}
     #{nickname}
    """


class BadgeRuleItem extends KDListItemView
  constructor: (options = {}, data) ->

    @propertySelect   = new KDSelectBox
      name            : 'rule-property'
      selectOptions   : [
        { title:"Follower", value:"counts.followers" }
        { title:"Likes"   , value:"counts.likes"     }
        { title:"Topics"  , value:"counts.topics"    }
        { title:"Follows" , value:"counts.following" }
      ]
      defaultValue    : if data.property then data.property else "counts.followers"

    @propertyAction   = new KDSelectBox
      name            : 'rule-action'
      selectOptions   : [
        { title: "more than"  , value:">" }
        { title: "less then"  , value:"<" }
      ]
      defaultValue    : if data.action then data.action else ">"

    @propertyVal      = new KDInputView
      name            : 'rule-value'
      placeholder     : "enter value"
      defaultValue    : if data.propVal then data.propVal else ""

    @removeRule       = new KDButtonView
      name            : 'removeRule'
      style           : 'remove-rule'
      title           : '-'
      callback        : ->
        @parent.getDelegate().emit "RemoveRuleFromList", @parent

    super options, data

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <div class="rule-item">
    {{> @propertySelect}}
    {{> @propertyAction}}
    {{> @propertyVal}}
    {{> @removeRule}}
    </div>
    """
