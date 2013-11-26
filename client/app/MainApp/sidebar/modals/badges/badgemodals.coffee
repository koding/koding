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
            Reward          :
              label         : "Reward"
              type          : "text"
              name          : "reward"
              defaultValue  : "#{@badge.reward  || "no reward"}"
            Rule            :
              label         : "Rule"
              type          : "text"
              name          : "rule"
              defaultValue  : "#{@badge.rule}"
            Description     :
              label         : "Description"
              type          : "text"
              name          : "description"
              defaultValue  : "#{@badge.description}"

    super options, data


class BadgeRemoveForm extends KDModalViewWithForms
  constructor:(options = {}, data)->
    {@badge} = data
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
            Cancel          :
              title         : "NO"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()

    super options, data


class UserBadgeListView extends JView

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
