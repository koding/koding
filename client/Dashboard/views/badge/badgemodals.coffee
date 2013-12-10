class NewBadgeForm extends JView

  constructor:(options = {}, data)->

    @badgeForm                = new KDModalViewWithForms
      title                   : "Add New Badge"
      overlay                 : "yes"
      width                   : 600
      height                  : "auto"
      tabs                    :
        callback              : (formData)=> @createBadgeAndAssign formData
        navigable             : yes
        forms                 :
          "New Badge"         :
            buttons           :
              Add             :
                title         : "Add"
                style         : "modal-clean-green"
                type          : "submit"
              Cancel          :
                title         : "Cancel"
                style         : "modal-clean-red"
            fields            :
              Title           :
                label         : "Title"
                type          : "text"
                name          : "title"
                placeholder   : "enter the name of the badge"
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "add badge name"
              Icon            :
                label         : "Badge Icon"
                type          : "text"
                name          : "iconURL"
                placeholder   : "enter the path of badge"
              Description     :
                label         : "Description"
                type          : "text"
                name          : "description"
                placeholder   : "Description of the badge to be showed to user"
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "permission"
                selectOptions : [
                    { title : "No Permission", value : "none"   }
                  ]
          "Rules"             :
            fields            : {}

    super options, data

    @updateRulesTabView()
    @updatePermissionBoxData()

  pistachio:->
    """
    {{> @badgeForm}}
    """

  updatePermissionBoxData:->
    selectRoles = []
    permissionBox = @badgeForm.modalTabs.forms["New Badge"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles)=>
      for role in roles
        selectRoles.push title : role.title, value : role._id
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView:->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules

  createBadgeAndAssign: (formData)->
    KD.remote.api.JBadge.create formData, (err, badge)=>
      badge.assignBadgeBatch formData.ids, (err) =>
        return err if err


class BadgeUpdateForm extends JView
  constructor:(options = {}, data)->
    {@badge} = data
    @badgeForm                = new KDModalViewWithForms
      title                   : "Modify Badge"
      overlay                 : "yes"
      width                   : 700
      height                  : "auto"
      tabs                    :
        goToNextFormOnSubmit  : no
        navigable             : yes
        forms                 :
          "Properties"        :
            callback          : (formData) =>
              @badge.modify formData, (err, badge)->
                return err if err
                new KDNotificationView
                  title       : "Badge Updated !"
                  duration    : 1000
            buttons           :
              Add             :
                title         : "Save"
                style         : "modal-clean-green"
                type          : "submit"
            fields            :
              Title           :
                label         : "Title"
                type          : "text"
                name          : "title"
                defaultValue  : @badge.title
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "badge name required"
              Icon            :
                label         : "Badge Icon"
                type          : "text"
                name          : "iconURL"
                defaultValue  : @badge.iconURL
              Description     :
                label         : "Description"
                type          : "text"
                name          : "description"
                defaultValue  : @badge.description
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "permission"
                defaultValue  : "none"
                selectOptions : [
                    { title   : "No Permission", value : "none"   }
                  ]
          "Rules"             :
            fields            : {}
          "Assign"            :
            fields            :
              Username        :
                label         : "User"
                type          : "hidden"
                nextElement   :
                  userWrapper :
                    itemClass : KDView
                    cssClass  : "completed-items"
            buttons           :
              Assign          :
                label         : ""
                title         : "Assign"
                style         : "modal-clean-green"
                callback      : (formData)=>
                  if @userController?.getSelectedItemData().length > 0
                    users = @userController?.getSelectedItemData()
                    userIds = user._id for user in users
                    @badge.assignBadgeBatch userIds, (err) =>
                      return err if err
                      new KDNotificationView
                        title : "Badge given to "+ users.length+" users."
          "Users"             :
            fields            : {}
          "Delete"            :
            fields            :
              Approval        :
                title         : ""
                label         : "Are you sure ?"
                itemClass     : KDLabelView
            buttons           :
              Remove          :
                label         : ""
                title         : "Remove"
                style         : "modal-clean-red"
                callback      : (formData)=>
                  modal = new BadgeRemoveForm {}, {@badge}
                  modal.setDelegate this


    @updatePermissionBoxData()
    @updateRulesTabView()
    @createUserAutoComplete()
    @updateBadgeUsersList()

    super options, data

  createUserAutoComplete:->
    @modalTabs = @badgeForm.modalTabs
    {fields, inputs, buttons} = @modalTabs.forms["Assign"]
    @userController       = new KDAutoCompleteController
      form                : @modalTabs.forms["Assign"]
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : fields.userWrapper
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        if /^@/.test inputValue
          query = 'profile.nickname': inputValue.replace /^@/, ''
          KD.remote.api.JAccount.one query, (err, account)=>
            if not account
              @userController.showNoDataFound()
            else
              callback [account]
        else
          KD.remote.api.JAccount.byRelevance inputValue, {}, (err, accounts)->
            callback accounts

    @userController.on "ItemListChanged", =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0
        account = accounts[0]
        {inputs} = @modalTabs.forms["Assign"]

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  updatePermissionBoxData:->
    selectRoles = []
    permissionBox = @badgeForm.modalTabs.forms["Properties"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles)=>
      for role in roles
        selectRoles.push title : role.title, value : role._id
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView: ->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules badge : @badge

  updateBadgeUsersList: ->
    parentView = @badgeForm.modalTabs.forms["Users"]
    parentView.addSubView new BadgeUsersList {}, {@badge}


class BadgeUsersList extends JView
  constructor:(options = {}, data) ->

    {@badge}                  = data
    @filteredUsersController = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "users"
        cssClass             : "user-list"
        itemClass            : BadgeUsersItem

    KD.remote.api.JBadge.fetchBadgeUsers @badge.getId(), (err, accounts)=>
      @filteredUsersController.instantiateListItems accounts

    @userView = @filteredUsersController.getListView()

    @userView.on "removeBadgeUser", (account) =>
      @badge.removeBadgeFromUser account, (err, account)=>
        return err if err
        new KDNotificationView
          title     : "Badge removed"
          duration  : 2000

    super options, data

  pistachio:->

    """
      {{>@userView}}
    """


class BadgeRemoveForm extends KDModalViewWithForms
  constructor:(options = {}, data)->
    options.title           or= 'Sure ?'
    options.tabs            ?=
      forms                 :
        deleteForm          :
          buttons           :
            yes             :
              title         : "YES"
              style         : "modal-clean-green"
              type          : "submit"
              callback      : =>
                {badge} = @getData()
                badge.deleteBadge (err)=>
                  return err if err
                  @destroy()
                  @getDelegate().destroy()
                  @getDelegate().getOptions().itemList.destroy()
            Cancel          :
              title         : "No"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()

    super options, data

#below 2 classes taken from old AdminModal.coffee
class MemberAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super options, data

    userInput = options.userInput or @getDelegate().userInput

    @addSubView @profileLink = \
      new AutoCompleteProfileTextView {userInput, shouldShowNick: yes}, data

  viewAppended:-> JView::viewAppended.call this


class MemberAutoCompletedItemView extends KDAutoCompletedItem

  viewAppended:->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
    JView::viewAppended.call this
