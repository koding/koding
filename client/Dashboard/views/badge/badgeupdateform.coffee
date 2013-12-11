class BadgeUpdateForm extends JView
  constructor:(options = {}, data)->
    super options, data

    {@badge}                  = @getData()
    @badgeForm                = new KDModalViewWithForms
      title                   : "Modify Badge"
      overlay                 : yes
      width                   : 700
      height                  : "auto"
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
                  modal = new BadgeRemoveForm {itemList}, {@badge}



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
      for role in roles
        selectRoles.push title : role.title, value : role._id
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView: ->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules {@badge}

  updateBadgeUsersList: ->
    parentView = @badgeForm.modalTabs.forms["Users"]
    parentView.addSubView new BadgeUsersList {@badge}

#below 2 classes taken from old AdminModal.coffee
class MemberAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super options, data

    userInput = options.userInput or @getDelegate().userInput

    @addSubView @profileLink = \
      new AutoCompleteProfileTextView {userInput, shouldShowNick: yes}, data

  viewAppended:JView::viewAppended


class MemberAutoCompletedItemView extends KDAutoCompletedItem

  viewAppended:->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
    viewAppended:JView::viewAppended
