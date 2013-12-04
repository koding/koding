class BadgeRules extends JView
  constructor:(options = {}, data) ->

    @badgeListViewController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "item"
        itemClass         : BadgeRuleItem

    @badgeListView = @badgeListViewController.getListView()

    @badgeListViewController.addItem {}

    @addRule          = new KDButtonView
      name            : 'addrule'
      style           : 'add-new-rule'
      title           : '+'
      callback        : =>
        @badgeListViewController.addItem {}

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

    @rulesInput       = new KDInputView
      type            : "hidden"
      name            : "badgerules"

    @userList = @filteredUsersController.getView()

    @badgeListView.on "RemoveRuleFromList", (item)=>
      @badgeListViewController.removeItem item

    @giveBadgeButton.hide()

    super options, data


  createUserSelector: (limit, skip)->

    # check filter properties
    ruleProperties =
      "follower"   : "counts.followers"
      "topic"      : "counts.topics"
      "like"       : "counts.likes"
      "following"  : "counts.following"
      "createdAt"  : "meta.createdAt"

    ruleActions    =
      "more"       : "$gt"
      "less"       : "$lt"
      "equal"      : ""

    selector   = {}
    ruleItems  = @badgeListViewController.getItemsOrdered()

    for ruleItem in ruleItems
      property = ruleItem.propertySelect.getValue()
      if ruleProperties[property]
        action = ruleItem.propertyAction.getValue()
        if ruleActions[action]
          #TODO : refactor
          operArr  = {}
          propVal  = ruleItem.propertyVal.getValue()
          tmpProp  = ruleProperties[property]
          tmpAct   = ruleActions[action]
          operArr[tmpAct]   = propVal
          selector[tmpProp] = operArr

    KD.remote.api.JAccount.someWithRelationship selector, {}, (err,users) =>
      return err if err
      ids = (user._id for user in users)
      @usersInput.setValue ids
      @filteredUsersController.removeAllItems()
      @filteredUsersController.instantiateListItems users

  pistachio:->
    """
    {{> @addRule}}
    {{> @doneButton}}
    {{> @badgeListView}}
    {{> @userList}}
    {{> @giveBadgeButton}}
    {{> @usersInput}}
    """

class BadgeUsersItem extends KDListItemView
  constructor: (options ={}, data)->
    super options, data
    @account = @getData()
    @profile  = new ProfileView {}, @account

  viewAppended: JView::viewAppended

  pistachio:->
    """
     {{> @profile}}
    """


class BadgeRuleItem extends KDListItemView
  constructor: (options = {}, data) ->
    @propertySelect   = new KDSelectBox
      name            : 'rule-property'
      selectOptions   : [
        { title:"Follower", value:"follower" }
        { title:"Likes"   , value:"like"     }
        { title:"Topics"  , value:"topic"    }
        { title:"Follows" , value:"following"}
        { title:"Created" , value:"createdAt"}
      ]

    @propertyAction   = new KDSelectBox
      name            : 'rule-action'
      selectOptions   : [
        { title: ">"  , value:"more"  }
        { title: "<"  , value:"less"  }
        { title: "="  , value:"equal" }
      ]

    @propertyVal      = new KDInputView
      name            : 'rule-value'
      placeholder     : "enter value"

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
      <ul class="list">
        <li>{{> @propertySelect}}</li>
        <li>{{> @propertyAction}}</li>
        <li>{{> @propertyVal}}</li>
        <li>{{> @removeRule}}</li>
      </ul>
    """
