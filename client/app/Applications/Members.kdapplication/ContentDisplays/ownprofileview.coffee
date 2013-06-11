class OwnProfileView extends JView

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

    {nickname} = memberData.profile
    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.followers is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Followers", {state:memberData}
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.following is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Following", {state:memberData}
    , memberData

    @likes = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.following is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Likes", {state:memberData}
    , memberData

    @aboutYou     = new PersonalFormAboutView {memberData}
    @skillTagView = new PersonalFormSkillTagView {memberData}

    @skillTagView.on "AutoCompleteNeedsTagData", (event)=>
      {callback,inputValue,blacklist} = event
      @fetchAutoCompleteDataForTags inputValue,blacklist,callback

  putNick:(nick)-> "@#{nick}"

  pistachio:->
    account      = @getData()
    {nickname}   = account.profile
    userDomain   = "#{account.profile.nickname}.#{KD.config.userSitesDomain}"
    amountOfDays = Math.floor (new Date - new Date(account.meta.createdAt)) / (24*60*60*1000)
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
      {cite{ @putNick #(profile.nickname)}}
      {div{#(onlineStatus)}}
    </div>

    <section>
      <div class="profileinfo">
        {{> @profileName}}
        {{> @location}}
        <h5>
          <a class="user-home-link no-right-overflow" href="http://#{userDomain}" target="_blank">#{userDomain}</a>
          <cite>member for #{if amountOfDays < 2 then 'a' else amountOfDays} day#{if amountOfDays > 1 then 's' else ''}.</cite>
        </h5>
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

  fetchAutoCompleteDataForTags:(inputValue,blacklist,callback)->
    KD.remote.api.JTag.byRelevanceForSkills inputValue, {blacklist}, (err,tags)->
      unless err
        callback? tags
      else
        log "there was an error fetching topics #{err.message}"
