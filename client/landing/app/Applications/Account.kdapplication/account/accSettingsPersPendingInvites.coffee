class AccountPersPendingInvitesListController extends KDListViewController

  constructor:(options, data)->
    options.cssClass or= 'account-pending-invites-list'
    super options, data

  loadView:->
    super

    KD.remote.api.JAccount.fetchPendingGroupInvitations (err, data)=>
      if err then warn err
      else
        if data and data.length > 0
          @instantiateListItems data
        else
          @getListView().addSubView new AccountPersPendingInvitesEmptyListItem


class AccountPersPendingInvitesList extends KDListView

  constructor:(options, data)->
    options.tagName   or= 'ul'
    options.itemClass or= AccountPersPendingInvitesListItem
    super options, data


class AccountPersPendingInvitesListItem extends KDListItemView

  constructor:(options = {}, data)->
    options.tagName  or= 'li'
    options.cssClass or= 'account-pending-invites-list-item'
    super options, data

    {invitation, group} = @getData()

    @addSubView formView = new KDFormView
    formView.addSubView new KDLabelView
      title    : group.title
      cssClass : 'main-label'

    formView.addSubView approveButton = new KDButtonView
      cssClass  : 'clean-gray'
      title     : 'Accept'
      callback  : =>
        invitation.acceptInvitationByInvitee (err)=>
          if err then warn err
          else
            @showMessage("Yay, you joined #{group.title}!")
            @hide()

    formView.addSubView declineButton = new KDButtonView
      cssClass  : 'clean-gray'
      title     : 'Ignore'
      callback  : =>
        invitation.ignoreInvitationByInvitee (err)=>
          if err then warn err
          else
            @showMessage("Fair enough, you refused the invitation to #{group.title}!")
            @hide()

  partial:->

  showMessage:(message)->
    new KDNotificationView
      title    : message
      duration : 2000

class AccountPersPendingInvitesEmptyListItem extends KDListItemView

  constructor:(options = {}, data)->
    options.tagName or= 'li'
    super options, data

  partial:(data)->
    '<span class="darkText">Yay, no pending invitations!</span>'