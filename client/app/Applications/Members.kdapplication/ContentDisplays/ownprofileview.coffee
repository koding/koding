class OwnProfileView extends JView

  constructor:(options={}, data)->
    super options, data

    memberData = @getData()

    @avatar = new AvatarStaticView
      size        :
        width     : 90
        height    : 90
      tooltip     :
        title     : "<p class='centertext'>please use gravatar.com<br/>to set your avatar</p>"
        placement : "below"
    , memberData

    for route in ['followers', 'following', 'likes']
      @[route] = new KDView
        tagName     : 'a'
        attributes  :
          href      : "/#{memberData.profile.nickname}/#{route[0].toUpperCase() + route[1..-1]}"
        pistachio   : "<cite/>{{#(counts[route] or 0)}} <span>#{route[0].toUpperCase() + route[1..-1]}</span>"
        click       : (event)->
          event.preventDefault()
          unless memberData.counts[route] is 0
            KD.getSingleton('router').handleRoute "/#{memberData.profile.nickname}/#{route}", {state:memberData}
      , memberData

    @profileName  = new PersonalFormNameView     {}, memberData
    @location     = new PersonalFormLocationView {}, memberData
    @aboutYou     = new PersonalFormAboutView    {}, memberData
    @skillTagView = new PersonalFormSkillTagView {}, memberData

    @skillTagView.on "AutoCompleteNeedsTagData", (event)=>
      {callback,inputValue,blacklist} = event
      @fetchAutoCompleteDataForTags inputValue,blacklist,callback

  putNick:(nick)-> "@#{nick}"
  putPresence:(state)->
    """
      <div class="presence #{state or 'offline'}">
        #{state or 'offline'}
      </div>
    """

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
      {div{ @putPresence #(onlineStatus)}}
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
