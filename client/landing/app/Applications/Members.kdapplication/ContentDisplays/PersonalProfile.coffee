class PersonalProfile extends KDView
  constructor:->
    super
    memberData = @getData()
    
    memberData.skillTags or= []
    
    @avatar      = new PersonalFormAvatarView null, memberData
    @profileName = new PersonalFormNameView null, memberData
    @location    = new PersonalFormLocationView null, memberData
    
    @followers   = new ProfileFollowersView null, memberData
    @following   = new ProfileFollowingView null, memberData
    
    @aboutYou    = new PersonalFormAboutWrapperView null, memberData
      
    @skillTagView = new PersonalFormSkillTagView null, memberData
    
    @setListeners()
                
  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
      
  pistachio:->
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
    </div>

    <section>
      <div class="profileinfo">
        {{> @profileName}}
        {{> @location}}
        <div class="profilestats">
          <div class="fers">
            {{> @followers}}
          </div>
          <div class="fing">
            {{> @following}}
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
    bongo.api.JTag.byRelevance inputValue, {blacklist}, (err,tags)->
      unless err
        callback? tags
      else
        log "there was an error fetching topics"
