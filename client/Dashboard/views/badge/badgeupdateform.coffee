class BadgeUpdateForm extends JView
  constructor:(options = {}, data)->
    super options, data
    {@badge}                  = @getData()
    @badgeForm                = new KDModalViewWithForms
      title                   : "Modify Badge"
      overlay                 : yes
      width                   : 700
      height                  : "auto"
      cssClass                : "modify-badge-modal"
      tabs                    :
        goToNextFormOnSubmit  : no
        navigable             : yes
        forms                 :
          "Properties"        :
            callback          : (formData) =>
              @badge.modify formData, (err, badge)->
                new KDNotificationView
                  title       : if err then err.message else "Badge Updated !"
                  duration    : 1000
            buttons           :
              Add             :
                title         : "Save"
                style         : "modal-clean-green"
                type          : "submit"
            fields            :
              Title           :
                label         : "Title"
                name          : "title"
                defaultValue  : @badge.title
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "badge name required"
              Icon            :
                label         : "Badge Icon"
                name          : "iconURL"
                defaultValue  : @badge.iconURL
              Description     :
                label         : "Description"
                name          : "description"
                defaultValue  : @badge.description
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "permission"
                disabled      : yes
                defaultValue  : @badge.role or "none"
                selectOptions : [
                    { title   : "No Permission", value : "none" }
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
                callback      : (formData) =>
                  if @userController?.getSelectedItemData().length > 0
                    users = @userController.getSelectedItemData()
                    idArray = (user._id for user in users)
                    @badge.assignBadgeBatch idArray, (err) =>
                      new KDNotificationView
                        title : if err then err.message else "Badge given "
                      @badgeUserList.loadUserList()
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
                  {itemList} = @getOptions()
                  modal = new BadgeRemoveForm {itemList:itemList,delegate:this}, {@badge}

    @badgeForm.once "viewAppended", =>
      KD.utils.wait 1827, =>
        @updatePermissionBoxData()
        @updateRulesTabView()
        @createUserAutoComplete()
        @updateBadgeUsersList()

  createUserAutoComplete:->
    {forms} = @badgeForm.modalTabs
    {fields, inputs, buttons} = forms["Assign"]
    @userController       = new KDAutoCompleteController
      form                : forms["Assign"]
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

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  updatePermissionBoxData:->
    selectRoles = []
    permissionBox = @badgeForm.modalTabs.forms["Properties"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles)=>
      tmpRoles = ["admin", "owner", "guest", "member"]
      for role in roles
        unless role.title in tmpRoles
          {title} = role
          selectRoles.push title:title, value:title
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView: ->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules {@badge}

  updateBadgeUsersList: ->
    parentView     = @badgeForm.modalTabs.forms["Users"]
    @badgeUserList = new BadgeUsersList {@badge}
    parentView.addSubView @badgeUserList

#below 2 classes taken from old AdminModal.coffee
class MemberAutoCompleteItemView extends KDAutoCompleteListItemView

  JView.mixin @prototype

  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super options, data
    userInput = options.userInput or @getDelegate().userInput
    @addSubView @profileLink = \
      new AutoCompleteProfileTextView {userInput, shouldShowNick: yes}, data


class MemberAutoCompletedItemView extends KDAutoCompletedItem
  viewAppended:->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
