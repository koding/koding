class OwnProfileView extends KDView
  constructor:->
    super
    memberData = @getData()

    memberData.skillTags or= []

    @avatar = new AvatarStaticView
      size        :
        width     : 90
        height    : 90
      tooltip     :
        title     : "<p class='centertext'>please use gravatar.com<br/>to set your avatar</p>"
        placement : "below"
    , memberData

    @profileName = new PersonalFormNameView {memberData}
    @location    = new PersonalFormLocationView {memberData}

    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if memberData.counts.followers is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'followers'
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'following'
    , memberData

    @likes = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createLikedContentDisplay", memberData
    , memberData

    @aboutYou     = new PersonalFormAboutView {memberData}
    @skillTagView = new PersonalFormSkillTagView {memberData}

    @setListeners()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  putNick:(nick)-> "@#{nick}"

  pistachio:->
    userDomain = "#{@getData().profile.nickname}.koding.com"
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
      {cite{ @putNick #(profile.nickname)}}
    </div>

    <section>
      <div class="profileinfo">
        {{> @profileName}}
        {{> @location}}
        <h5><span class='icon fl'></span><a class="user-home-link right-overflow" href="http://#{userDomain}" target="_blank">#{userDomain}</a></h5>
        <div class="profilestats">
          <div class="fers">
            {{> @followers}}
          </div>
          <div class="fing">
            {{> @following}}
          </div>
          <div class="liks">
            {{> @likes}}
          </div>
        </div>

        <div class="profilebio">
          {{> @aboutYou}}
        </div>

        <div class="personal-skilltags">
          {{> @skillTagView}}
        </div>

      </div>
    </section>
    """

  setListeners:->
    @listenTo
      KDEventTypes        : "AutoCompleteNeedsTagData"
      listenedToInstance  : @skillTagView
      callback      : (pubInst,event)=>
        {callback,inputValue,blacklist} = event
        @fetchAutoCompleteDataForTags inputValue,blacklist,callback

  fetchAutoCompleteDataForTags:(inputValue,blacklist,callback)->
    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err,tags)->
      unless err
        callback? tags
      else
        log "there was an error fetching topics"
