class MembersListViewController extends KDListViewController

  loadView:(mainView)->
    super
    @getListView().on 'ItemWasAdded', (view)=> @addListenersForItem view

  addItem:(member, index, animation = null) ->
    @getListView().addItem member, index, animation

  addListenersForItem:(item)->
    data = item.getData()

    data.on 'FollowCountChanged', (followCounts)=>
      {followerCount, followingCount, newFollower, oldFollower} = followCounts
      data.counts.followers = followerCount
      data.counts.following = followingCount
      item.setFollowerCount followerCount
      switch KD.getSingleton('mainController').getVisitor().currentDelegate
        when newFollower, oldFollower
          if newFollower then item.unfollowTheButton() else item.followTheButton()

    return this

  getTotalMemberCount:(callback)->
    KD.whoami().count? @getOptions().filterName, callback
