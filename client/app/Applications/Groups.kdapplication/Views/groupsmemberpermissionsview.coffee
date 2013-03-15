class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "groups-member-permissions-view"

    super

    @listController = new KDListViewController
      itemClass     : GroupsMemberPermissionsListItemView
    @listWrapper    = @listController.getView()

    @loader         = new KDLoaderView
      cssClass      : 'loader'
    @loaderText     = new KDView
      partial       : 'Loading Member Permissions…'
      cssClass      : ' loader-text'

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @bound 'memberRolesChange'

    @refresh()

  fetchSomeMembers:(selector={})->
    groupData = @getData()
    @listController.removeAllItems()
    @loader.show()
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
              userRolesHash[userRole.targetId] = userRole.as

            list.getOptions().userRoles = userRolesHash
            options =
              limit : 20
              sort  : { timestamp: -1 }
            groupData.fetchMembers selector, options, (err, members)=>
              if err then warn err
              else
                @listController.instantiateListItems members
                @loader.hide()
                @loaderText.hide()

  refresh:->
    @timestamp = new Date 0
    @fetchSomeMembers {timestamp: $gte: @timestamp}

  memberRolesChange:(member, roles)->
    @getData().changeMemberRoles member.getId(), roles, (err)-> console.log {arguments}

  viewAppended:->
    super
    @loader.show()
    @loaderText.show()

  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    {{> @listWrapper}}
    """