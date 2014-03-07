class BadgeRules extends JView
  constructor:(options = {}, data) ->
    super options, data

    @badgeRulesListController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-rules"
        itemClass         : BadgeRuleItem
        scrollView        : no
        wrapper           : no

    @badgeListView = @badgeRulesListController.getView()

    @addRuleButton    = new KDButtonView
      name            : 'addrule'
      style           : 'add-new-rule solid green'
      title           : 'Add new rule'
      callback        : =>
        @badgeRulesListController.addItem {}

    @doneButton       = new KDButtonView
      name            : 'listdone'
      style           : 'rule-set-done solid green'
      title           : 'done'
      callback        : =>
        @createUserSelector()
        @giveBadgeButton.show()

    @totalUserCount   = new KDCustomHTMLView
      partial         : ""

    @filteredUsersController = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "users"
        cssClass             : "user-list"
        itemClass            : BadgeUsersItem

    @giveBadgeButton  = new KDButtonView
      name            : 'createbadge'
      style           : 'create-badge-button solid green'
      title           : 'Create'
      type            : "submit"
      loader          : yes

    @usersInput       = new KDInputView
      type            : "hidden"
      name            : "ids"

    @rule             = new KDInputView
      type            : "hidden"
      name            : "rule"

    @userList    = @filteredUsersController.getView()
    userListView = @filteredUsersController.getListView()
    listView     = @badgeRulesListController.getListView()
    listView.on "RemoveRuleFromList", (item)=>
      @badgeRulesListController.removeItem item

    @giveBadgeButton.hide()

    @once "BadgeCreated" , =>
      @giveBadgeButton.loader.hide()
      @giveBadgeButton.hide()
      @addRuleButton.hide()
      @doneButton.hide()
      new KDNotificationView
        title      : "Badge created"
        duration   : "2000"

    userListView.on "RemoveBadgeUser", (ac) =>
      tmpArr = @usersInput.getValue().split ','
      index = tmpArr.indexOf ac._id
      tmpArr.splice index, 1
      @usersInput.setValue tmpArr.toString()
      @usersInput.getValue()

    {@badge} = @getOptions()
    if @badge
      @updateRulesList()
      #hide add new rule
      @addRuleButton.disable()
      @doneButton = new KDCustomHTMLView

  createUserSelector: (limit, skip)->
    selector   = {}
    rules      = ""
    ruleItems  = @badgeRulesListController.getItemsOrdered()
    for ruleItem, key in ruleItems
      countProp = ruleItem.propertySelect.getValue()
      property = "counts.#{countProp}"
      tmpAct   = ruleItem.propertyAction.getValue()
      propVal  = ruleItem.propertyVal.getValue()

      operArr  = {}
      action = if tmpAct is "<" then "$lt" else "$gt"

      operArr[action]    = propVal
      selector[property] = operArr
      rules += countProp + tmpAct + propVal
      rules += "+" if key < ruleItems.length - 1

    @rule.setValue rules
    KD.remote.api.JAccount.someWithRelationship selector, {}, (err, users) =>
      return KD.showError err if err
      @usersInput.setValue (user._id for user in users)
      @filteredUsersController.removeAllItems()
      @totalUserCount.setPartial "Total users : #{users.length}"
      @filteredUsersController.instantiateListItems users

  updateRulesList:->
    ruleArray = @badge.rule.split "+"
    for rule in ruleArray
      decoded   = Encoder.htmlDecode rule
      actionPos = decoded.search /[\<\>\=]/
      action    = decoded.substr actionPos, 1
      property  = decoded.substr 0, actionPos
      propVal   = decoded.substr actionPos + 1
      @badgeRulesListController.addItem {property, action, propVal}

  pistachio:->
    """
    {{> @addRuleButton}}
    {{> @badgeListView}}
    {{> @totalUserCount}}
    {{> @doneButton}}
    {{> @userList}}
    {{> @giveBadgeButton}}
    {{> @usersInput}}
    {{> @rule}}
    """


class BadgeUsersItem extends KDListItemView
  constructor: (options ={}, data)->
    super options, data
    @avatar    = new AvatarImage
      size     :
        width  : 40
    , @getData()

    @remove    = new KDButtonView
      title    : "x"
      cssClass : "solid red"
      callback : =>
        @getDelegate().removeItem this
        @getDelegate().emit "RemoveBadgeUser", @getData()

  viewAppended: JView::viewAppended

  pistachio:->
    """
     {{> @avatar}}
     {{ #(profile.nickname)}}
     {{> @remove}}
    """


class BadgeRuleItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.cssClass = 'rule-item'
    super options, data

    @propertySelect   = new KDSelectBox
      name            : 'rule-property'
      selectOptions   : [
        { title:"Follower"          , value:"followers"        }
        { title:"Likes"             , value:"likes"            }
        { title:"Topics"            , value:"topics"           }
        { title:"Follows"           , value:"following"        }
        { title:"Comments"          , value:"comments"         }
        { title:"Invitations"       , value:"invitations"      }
        { title:"Referred Users"    , value:"referredUsers"    }
        { title:"Last Login"        , value:"lastLoginDate"    }
        { title:"Status Updates"    , value:"statusUpdates"    }
        { title:"Twitter Followers" , value:"twitterFollowers" }
        { title:"Staff Likes"       , value:"staffLikes"       }
      ]
      defaultValue    : data.property or "followers"
      disabled        : !!data.propVal

    @propertyAction   = new KDSelectBox
      name            : 'rule-action'
      selectOptions   : [
        { title: "more than"  , value:">" }
        { title: "less then"  , value:"<" }
      ]
      defaultValue    : data.action or ">"
      disabled        : if data.propVal then yes else no

    @propertyVal      = new KDInputView
      name            : 'rule-value'
      placeholder     : "enter value"
      defaultValue    : data.propVal or ""
      disabled        : if data.propVal then yes else no

    @removeRule       = new KDButtonView
      name            : 'removeRule'
      style           : 'remove-rule solid red'
      title           : '-'
      callback        : =>
        @getDelegate().emit "RemoveRuleFromList", this

    @removeRule.hide() if data.propVal
  viewAppended: JView::viewAppended

  pistachio:->
    """
    {{> @propertySelect}}
    {{> @propertyAction}}
    {{> @propertyVal}}
    {{> @removeRule}}
    """
