class UserBadgeView extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data
    {iconURL, description} = @getData()

    @badgeIcon  = new KDCustomHTMLView
      tagName     : 'img'
      size        :
          width   : 70
          height  : 70
      attributes  :
        src       : iconURL
        title     : description or ''

  pistachio:->
    """
      {{> @badgeIcon}}
    """

class UserPropertyList extends JView
  constructor:(options = {}, data)->
    # ONLY ADMINS CAN SEE THAT VIEW
    super options, data
    {counts} = @getData()

    @followers     = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Follower count : <span class='number'>#{counts.followers}</span>"
      cssClass     : "badge-property"

    @following     = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Following count : <span class='number'>#{counts.following}</span>"
      cssClass     : "badge-property"
    @comments      = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Comments count : <span class='number'>#{counts.comments}</span>"
      cssClass     : "badge-property"
    @invitations   = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Invitations count : <span class='number'>#{counts.invitations}</span>"
      cssClass     : "badge-property"
    @lastLoginDate = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Last Login Date: <span class='number'>#{counts.lastLoginDate}</span>"
      cssClass     : "badge-property"
    @likes         = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Likes count : <span class='number'>#{counts.likes}</span>"
      cssClass     : "badge-property"
    @referredUsers = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Referred User count : <span class='number'>#{counts.referredUsers}</span>"
      cssClass     : "badge-property"
    @statusUpdates = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Status updates count : <span class='number'>#{counts.statusUpdates}</span>"
      cssClass     : "badge-property"
    @topics        = new KDCustomHTMLView
      tagName      : "p"
      partial      : "Topics count : <span class='number'>#{counts.topics}</span>"
      cssClass     : "badge-property"

  pistachio:->
    """
     <a href="#">User Properties</a>
      {{> @followers}}
      {{> @following}}
      {{> @comments}}
      {{> @invitations}}
      {{> @lastLoginDate}}
      {{> @likes}}
      {{> @referredUsers}}
      {{> @statusUpdates}}
      {{> @topics}}
    """

