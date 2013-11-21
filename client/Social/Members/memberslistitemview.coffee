class MembersListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.type          = "members"
    options.avatarSizes or= [60, 60] # [width, height]

    super options, data

    memberData = @getData()
    options    = @getOptions()

    @avatar = new AvatarView
      size           :
        width        : options.avatarSizes[0]
        height       : options.avatarSizes[1]
      showStatus     : yes
      statusDiameter : 5
    , memberData

    if (memberData.profile.nickname is KD.whoami().profile.nickname) or \
        memberData.type is 'unregistered'
    then @followButton = new KDView
    else @followButton = new MemberFollowToggleButton
      style       : "follow-btn"
      loader      :
        color     : "#333333"
        diameter  : 18
        top       : 11
    , memberData

    memberData.locationTags or= []
    if memberData.locationTags.length < 1
      memberData.locationTags[0] = "Earth"

    @location     = new KDCustomHTMLView
      partial     : memberData.locationTags[0]
      cssClass    : "location"

    @profileLink = new ProfileLinkView {}, memberData
    @profileLink.render()

  click:(event)->
    KD.utils.showMoreClickHandler.call this, event
    targetATag = $(event.target).closest('a')
    if targetATag.is(".followers") and parseInt(targetATag.text()) isnt 0
      KD.getSingleton('router').handleRoute "/#{@getData().profile.nickname}/Followers"
    else if targetATag.is(".following") and parseInt(targetATag.text()) isnt 0
      KD.getSingleton('router').handleRoute "/#{@getData().profile.nickname}/Following"

  clickOnMyItem:(event)->
    if $(event.target).is ".propagateProfile"
      @emit "VisitorProfileWantsToBeShown", {content : @getData(), contentType : "member"}

  viewAppended:->
    @setClass "member-item"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <span>
        {{> @avatar}}
      </span>

      <div class='member-details'>
        <header class='personal'>
          <h3>{{> @profileLink}}</h3> {{#(profile.nickname)}}
          <span>{{> @location}}</span>
        </header>

        <p>{{ @utils.applyTextExpansions #(profile.about), yes}}</p>

        <footer>
          <span class='button-container'>{{> @followButton}}</span>
          <a class='followers' href='#'> <cite></cite> {{#(counts.followers)}} Followers</a>
          <a class='following' href='#'> <cite></cite> {{#(counts.following)}} Following</a>
          <time class='timeago hidden'>
            <span class='icon'></span>
            <span>
              Active <cite title='{{#(meta.modifiedAt)}}'></cite>
            </span>
          </time>
        </footer>

      </div>
    """
