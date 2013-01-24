class GroupsComingSoon extends KDView
  viewAppended:()->
    @setClass "coming-soon-page"
    @setPartial @partial

  partial:()->
    partial = $ """
      <div class='comingsoon'>
        <img src='../images/topicsbig.png' alt='Groups are coming soon!'><h1>Koding Groups</h1>
        <h2>Coming soon</h2>
      </div>
    """

class GroupsMainView extends KDView

  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()
    # @addSubView new CommonFeedMessage
    #   title           : "<p>Topic tags organize shared content on Koding. Tag items when you share, and follow topics to see content relevant to you in your activity feed.</p>"
    #   messageLocation : 'Topics'

  createTopicsHint:->
    listController.scrollView.addSubView notice = new KDCustomHTMLView
      cssClass  : "groups-hint"
      tagName   : "p"
      partial   : "<span class='icon'></span>"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : notice
      callback : (pubInst,event)->
        if $(event.target).is "a.closeme"
          notice.$().animate marginTop : "-16px", opacity : 0.001,150,()->notice.destroy()

  # addAddTopicButton:->
  #   new KDButtonView
  #     title     : "Add Topic"
  #     style     : "small-gray"
  #     callback  : ->
  #       modal = new KDModalViewWithForms
  #         title                   : "Add a Topic"
  #         content                 : ""
  #         overlay                 : yes
  #         width                   : 500
  #         height                  : "auto"
  #         cssClass                : "new-kdmodal"
  #         tabs                    :
  #           callback          : (formData,event)->
  #             mainView.emit "AddATopicFormSubmitted",formData
  #           forms                 :
  #             "Add a topic"       :
  #               fields            :
  #                 Name            :
  #                   type          : "text"
  #                   name          : "title"
  #                   placeholder   : "give a name to your topic..."
  #                   validate      :
  #                     rules       :
  #                       required  : yes
  #                     messages    :
  #                       required  : "Topic name is required!"
  #                 Description     :
  #                   type          : "textarea"
  #                   name          : "body"
  #                   placeholder   : "and give topic a description..."
  #               buttons           :
  #                 Add             :
  #                   style         : "modal-clean-gray"
  #                   type          : 'submit'
  #                 Cancel          :
  #                   style         : "modal-cancel"
  #                   callback      : ()-> modal.destroy()


class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "groups-member-permissions-view"

    super

    groupData       = @getData()
    @listController = new KDListViewController
      itemClass     : GroupsMemberPermissionsListItemView
    @listWrapper    = @listController.getView()
    @loader         = new KDLoaderView
      size          :
        width       : 32

    list = @listController.getListView()
    list.getOptions().group = groupData
    groupData.fetchRoles (err, roles)=>
      if err then warn err
      else
        list.getOptions().roles = roles

        groupData.fetchUserRoles (err, userRoles)=>
          if err then warn err
          else
            userRolesHash = {}
            for userRole in userRoles
              userRolesHash[userRole.sourceId] = userRole.as

            list.getOptions().userRoles = userRolesHash

            groupData.fetchMembers (err, members)=>
              if err then warn err
              else
                @listController.instantiateListItems members
                @loader.hide()

  viewAppended:->

    super

    @loader.show()


  pistachio:->

    """
      {{> @loader}}
      {{> @listWrapper}}
    """

class GroupsMemberPermissionsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = 'formline clearfix'
    options.type     = 'member-item'

    super options, data

    data               = @getData()
    list               = @getDelegate()
    {roles, userRoles} = list.getOptions()
    @profileLink       = new ProfileTextView {}, data
    @usersRole         = userRoles[data.getId()]

    @userRole          = new KDCustomHTMLView
      partial          : @usersRole
      cssClass         : 'ib role'

    @editLink          = new CustomLinkView
      title            : 'Edit'
      cssClass         : 'fr'
      icon             :
        cssClass       : 'edit'
      click            : @showEditMemberRolesView.bind @

    @saveLink        = new CustomLinkView
      title            : 'Save'
      cssClass         : 'fr hidden'
      icon             :
        cssClass       : 'save'
      click            : =>
        @hideEditMemberRolesView()
        log "save"

    @cancelLink        = new CustomLinkView
      title            : 'Cancel'
      cssClass         : 'fr hidden'
      icon             :
        cssClass       : 'delete'
      click            : @hideEditMemberRolesView.bind @

    @editContainer     = new KDView
      cssClass         : 'edit-container hidden'

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt @
        @hideEditMemberRolesView()

  showEditMemberRolesView:->

    list           = @getDelegate()
    editView       = new GroupsMemberRolesEditView delegate : @
    editorsRoles   = list.getOptions().editorsRoles
    {group, roles} = list.getOptions()
    list.emit "EditMemberRolesViewShown", @

    @editLink.hide()
    @cancelLink.show()
    @saveLink.show()
    @editContainer.show()
    @editContainer.addSubView editView

    unless editorsRoles
      group.fetchMyRoles (err, editorsRoles)=>
        if err
          log err
        else
          list.getOptions().editorsRoles = editorsRoles
          editView.setRoles editorsRoles, roles
          editView.addViews()
    else
      editView.setRoles editorsRoles, roles
      editView.addViews()

  hideEditMemberRolesView:->

    @editLink.show()
    @cancelLink.hide()
    @saveLink.hide()
    @editContainer.hide()
    @editContainer.destroySubViews()

  viewAppended:JView::viewAppended

  pistachio:->
    """
    <section>
      {{> @profileLink}}
      {{> @userRole}}
      {{> @editLink}}
      {{> @saveLink}}
      {{> @cancelLink}}
    </section>
    {{> @editContainer}}
    """

class GroupsMemberRolesEditView extends JView

  constructor:(options = {}, data)->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles:(editorsRoles, allRoles)->

    allRoles = allRoles.reduce (acc, role)->
      acc.push role.title  unless role.title in ['owner', 'guest']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }


  addViews:->

    @loader.hide()

    radioGroup = new KDInputRadioGroup
      name         : 'user-role'
      defaultValue : @roles.usersRole
      radios       : @roles.allRoles.map (role)-> {value : role, title: role.capitalize()}

    @addSubView radioGroup, '.radios'

    @addSubView (new KDButtonView
      title    : "Make Owner"
      cssClass : 'modal-clean-gray'
      callback : -> log "Transfer Ownership"
    ), '.buttons'

    @addSubView (new KDButtonView
      title    : "Kick"
      cssClass : 'modal-clean-red'
      callback : -> log "Kick user"
    ), '.buttons'

    @$('.buttons').removeClass 'hidden'


  pistachio:->
    """
      {{> @loader}}
      <div class='radios'/>
      <div class='buttons hidden'/>
    """

  viewAppended:->

    super

    @loader.show()
