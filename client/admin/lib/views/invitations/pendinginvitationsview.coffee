kd                    = require 'kd'
KDView                = kd.View
remote                = require('app/remote').getInstance()
InvitedItemView       = require './inviteditemview'
KDCustomHTMLView      = kd.CustomHTMLView
TeamMembersCommonView = require '../members/teammemberscommonview'


module.exports = class PendingInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    options.listViewItemClass        = InvitedItemView
    options.searchInputPlaceholder   = 'Find by email or first name'
    options.listViewItemOptions    or= statusType: 'pending'
    options.statusType             or= 'pending'
    options.noItemFoundWidget      or= new KDCustomHTMLView
      partial  : 'There is no pending invitation.'
      cssClass : 'hidden no-item-view'
    options.sortOptions            or= [
      { title: 'Send date',  value: 'modifiedAt' } # sort by -1
      { title: 'Email',      value: 'email'      } # sort by  1
      { title: 'First name', value: 'firstName'  } # sort by  1
      { title: 'Last name',  value: 'lastName'   } # sort by  1
    ]

    super options, data


  fetchMembers: ->

    return if @isFetching

    @isFetching    = yes
    { statusType } = @getOptions()
    query          = @searchInput.getValue()
    options        = { @skip, sort: @getSortOptions() }
    method         = 'some'
    selector       = status: statusType

    if query
      method = 'search'
      selector.query = query

    remote.api.JInvitation[method] selector, options, (err, invitations) =>

      if err
        @listController.lazyLoader.hide()
        return kd.warn err

      @listMembers invitations
      @isFetching = no


  search: ->

    @skip  = 0
    @query = @searchInput.getValue()

    @refresh()

    if @query.length then @searchClear.show() else @searchClear.hide()


  getSortOptions: ->

    sortDirections = { modifiedAt: -1, email: 1, firstName: 1, lastName: 1 }
    sortType       = @sortSelectBox.getValue()
    sort           = {}
    sort[sortType] = sortDirections[sortType]

    return sort
