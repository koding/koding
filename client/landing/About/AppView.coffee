class AboutView extends KDView


  viewAppended:->

    @addSubView new KDHeaderView
      title    : "The Team"
      type     : 'big'
      cssClass : 'team-title'

    @activeController = new KDListViewController
      itemClass   : AboutListItem
      listView    : new KDListView
        tagName   : 'ul'
      scrollView  : no
      wrapper     : no
    ,
      items       : KD.team.active

    @addSubView @activeController.getView()


    canSeeExMembers = no

    for member in KD.team.active when KD.nick() is member.username
      canSeeExMembers = yes
      break

    return  unless canSeeExMembers

    @suspendedController = new KDListViewController
      itemClass   : AboutListItem
      listView    : new KDListView
        tagName   : 'ul'
      scrollView  : no
      wrapper     : no
    ,
      items       : KD.team.suspended

    @addSubView new KDHeaderView
      title    : "Ex-members"
      type     : 'big'
      cssClass : 'team-title'
    @addSubView @suspendedController.getView()



class AboutListItem extends KDListItemView

  constructor:(options={}, data)->

    options.tagName = 'li'
    options.type    = 'team'

    super options, data

    {username} = @getData()
    @avatar    = new AvatarImage
      origin   : username
      bind     : 'load'
      load     : -> @setClass 'in'
      size     :
        width  : 160
    @link      = new ProfileLinkView origin : username


  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <figure>
      {{> @avatar}}
    </figure>
    <figcaption>
      {{> @link}}
      {cite{ #(title)}}
    </figcaption>
    """

