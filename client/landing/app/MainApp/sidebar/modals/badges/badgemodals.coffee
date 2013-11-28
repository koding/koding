class NewBadgeForm extends JView

  constructor:(options = {}, data)->
    @badgeForm                = new KDModalViewWithForms
      title                   : "Add New Badge"
      overlay                 : "yes"
      width                   : 600
      height                  : "auto"
      tabs                    :
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
            callback          : (formData)=>
              KD.remote.api.JBadge.create formData, (err, badge) =>
                {badgeListController} = @getOptions()
                badgeListController.addItem badge
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
              Reward          :
                label         : "Reward"
                type          : "text"
                name          : "reward"
                placeholder   : "reward of badge"
              Rule            :
                label         : "Rule"
                type          : "text"
                name          : "rule"
                placeholder   : "when this badge will be gained"
              Description     :
                label         : "Description"
                type          : "text"
                name          : "description"
                placeholder   : "Description of the badge to be showed to user"
          "Rules"             :
            buttons           :
              Add             :
                title         : "Add"
                style         : "modal-clean-green"
                type          : "submit"
              Cancel          :
                title         : "Cancel"
                style         : "modal-clean-red"
            fields            :
              Permissions     :
                label         : "Reward"
                type          : "select"
                name          : "reward"
    super options, data


  pistachio:->
    """
    {{> @badgeForm}}
    """

class BadgeUpdateForm extends KDModalViewWithForms

  constructor:(options = {}, data)->
    {@badge} = data
    options.cssClass = 'delete-badge-view'
    options.tabs            ?=
      forms                 :
        updateForm          :
          buttons           :
            Add             :
              title         : "Update"
              style         : "modal-clean-green"
              type          : "submit"
            Cancel          :
              title         : "Cancel"
              style         : "modal-clean-red"
              type          : "Reset"
          callback          : (formData)=>
            @badge.modify formData, (err,badge) =>
              return err if err
          fields            :
            Title           :
              label         : "Title"
              type          : "text"
              name          : "title"
              defaultValue  : "#{@badge.title}"
              validate      :
                rules       :
                  required  : yes
                messages    :
                  required  : "add badge name"
            Icon            :
              label         : "Badge Icon"
              type          : "text"
              name          : "iconURL"
              defaultValue  : "#{@badge.iconURL}"
              validate      :
                rules       :
                  required  : yes
                messages    :
                  required  : "add badge icon"
            Description     :
              label         : "Description"
              type          : "text"
              name          : "description"
              defaultValue  : "#{@badge.description}"
            Remove          :
              label         : "Remove Badge"
              itemClass     : KDButtonView
              title         : "Delete"
              callback      : =>
                # TODO : USE setDelegate
                new BadgeRemoveForm delegate:this,{@badge}

    super options, data


class BadgeRemoveForm extends KDModalViewWithForms
  constructor:(options = {}, data)->
    # TODO : get delegate proper way !
    {@delegate,@badge} = data
    options.title           or= 'Please confirm badge deletion'
    options.tabs            ?=
      forms                 :
        deleteForm          :
          buttons           :
            yes             :
              title         : "YES"
              style         : "modal-clean-green"
              type          : "submit"
              callback      : =>
                @badge.deleteBadge (err)=>
                  return err if err
                  @destroy()
                  @delegate.destroy()
            Cancel          :
              title         : "NO"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()

    super options, data


class AssignBadgeView extends JView

  constructor:(options = {}, data)->
    options.cssClass = "badges"
    super options, data

    @listController       = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-assignment-list"
        itemClass         : BadgeAssignmentListItem

    @list = @listController.getView()

    @listController.getListView().on "BadgeStateChanged", (state, badge) =>
      account = @getData()
      if state
        badge.assignBadge account, (err,relationship)=>
          return err if err
      else
        badge.removeBadgeFromUser account, (err) =>
          return err if err


  setAccount: (account)->
    @setData account
    @createBadgeListing()


  createBadgeListing: ->
    # get all badges
    KD.remote.api.JBadge.listBadges {}, (err, badges)=>
      return callback err if err
      badgeList = []
      # get user's badges
      KD.remote.api.JBadge.getUserBadges @getData(), (err, userBadges)=>
        # check if users has badges
        badges.every (badge, i)=>
          tmpBadge = {badge}
          for userBadge in userBadges
            if userBadge._id is badge._id
              tmpBadge.userHas = yes
          badgeList.push tmpBadge
        @listController.instantiateListItems badgeList

  pistachio:->
    """
    {{> @list}}
    """
