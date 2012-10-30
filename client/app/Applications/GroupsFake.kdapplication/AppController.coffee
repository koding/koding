class GroupsFakeController extends AppController

  constructor:(options = {}, data)->

    options.view = new KDView
      cssClass : "content-page groups"

    super options, data

  bringToFront:()->
    super name : "Groups"

  loadView:(mainView)->
    mainView.addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()
    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass             : GroupsListItemView
      limitPerPage          : 20
      help                  :
        subtitle            : "Learn About Groups"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">Group Tags organize content that users share on Koding. Follow the groups you are interested in and we'll include the tagged items in your activity feed.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All"
          optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
          dataSource        : (selector, options, callback)=>
            @utils.wait 500, => callback null, dummyData
        public              :
          title             : "Public"
          dataSource        : (selector, options, callback)=>
            @utils.wait 500, => callback null, dummyData
        private             :
          title             : "Private"
          dataSource        : (selector, options, callback)=>
            @utils.wait 500, => callback null, dummyData
      sort                  :
        'counts.followers'  :
          title             : "Most popular"
          direction         : -1
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.tagged'     :
          title             : "Most activity"
          direction         : -1
    }, (controller)=>
      mainView.addSubView @_lastSubview = controller.getView()

  dummyData =

    [
        title       : "Koding"
        description : "This group welcomes everyone, the main group of all."
        avatar      : "https://twimg0-a.akamaihd.net/profile_images/2343198892/hlzehyho8ulow7694ele_normal.png"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 22445
          posts     : 4534
      ,
        title       : "Koding Staff"
        description : "Exclusive to Koding staff."
        avatar      : "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc7/373271_109012155844171_296125410_q.jpg"
        isPrivate   : yes
        visible     : yes
        counts      :
          members   : 12
          posts     : 310
      ,
        title       : "Acme Corporation"
        description : "There were six people who loved to watch television, but they didn't like what they saw. Armed with determination and a strong will to change the course of television, they wrote their own shows, but that wasn't enough, they had to sell them. They went straight to the networks, but the networks were not ready for them. But did that stop them? No. They built their own network and they liked what they saw."
        avatar      : "http://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Acme_anvil.gif/200px-Acme_anvil.gif"
        isPrivate   : yes
        visible     : yes
        counts      :
          members   : 453
          posts     : 2451
      ,
        title       : "Tower Project"
        description : "Space, the final frontier. These are the voyages of the starship Enterprise. Its five year mission: to explore strange new worlds, to seek out new life and new civilizations, to boldly go where no man has gone before!"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 124
          posts     : 1407
      ,
        title       : "Joomla Devs"
        description : "Joomla is an award-winning content management system (CMS), which enables you to build Web sites and powerful online applications. Many aspects, including its ease-of-use and extensibility, have made Joomla the most popular Web site software available. Best of all, Joomla is an open source solution that is freely available to everyone."
        avatar      : "http://opensourcematters.org/images/stories/logos/conditional-use/Joomla_Symbol_BW_TM.png"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 124
          posts     : 1407
      ,
        title       : "TYPO3 - The Enterprise CMS"
        description : "TYPO3 is an enterprise-class, Open Source CMS (Content Management System), used internationally to build and manage websites of all types, from small sites for non-profits to multilingual enterprise solutions for large corporations."
        avatar      : "http://typo3.org/fileadmin/t3org/images/FM-styleguide/1_TYPO3_Logos/fullLogo_SafeArea.jpg"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 65
          posts     : 312
      ,
        title       : "Wordpress Plugin Developers"
        description : "Its five year mission: to explore strange new worlds, to seek out new life and new civilizations, to boldly go where no man has gone before!"
        avatar      : "http://s.wordpress.org/about/images/wordpress-logo-simplified-bg.png"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 124
          posts     : 1407
      ,
        title       : "Drupal Development Group"
        description : "Drupal is an open source content management platform powering millions of websites and applications. It’s built, used, and supported by an active and diverse community of people around the world."
        avatar      : "http://drupal.org/files/druplicon.small_.png"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 540
          posts     : 4503
      ,
        title       : "GIT Users"
        description : "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency."
        avatar      : "http://git-scm.com/images/logos/logomark-orange.png"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 65
          posts     : 312
      ,
        title       : "www agency, Barcelona"
        description : "Enter at your peril, past the vaulted door. Impossible things will happen that the world's never seen before. In Dexter's laboratory lives the smartest boy you've ever seen, but Dee Dee blows his experiments to Smithereens! There's gloom and doom when things go boom in Dexter's lab!"
        avatar      : "http://www.miroplast.com/photos/Barselona_Logo_cut.jpg"
        isPrivate   : no
        visible     : yes
        counts      :
          members   : 124
          posts     : 1407
    ]


class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.type   = 'group'
    data.avatar  or= "#{KD.apiUri}/images/defaultavatar/default.avatar.60.png"

    super

    @avatar = new KDCustomHTMLView
      tagName    : "img"
      cssClass   : "avatar"
      attributes :
        src      : @getData().avatar
    @join   = new KDButtonView title : "Join", style : "editor-button"
    # @follow = new KDButtonView title : "Follow", style : "small-gray"

  viewAppended: JView::viewAppended

  pistachio :->

    {isPrivate} = @getData()

    """
      #{if isPrivate then '<cite class="rt">PRIVATE</cite>' else ''}
      <div class='fl'>
        {{> @avatar}}
        {{> @join}}
      </div>
      <div class='right-overflow'>
        <h2>
          <a href='#'>{{ #(title)}}</a>
        </h2>
        <section>
          {p.desc{ #(description)}}
          <div>
            <figure><span class='members'/>{{ #(counts.members)}} Members</figure>
            <figure><span class='posts'/>{{ #(counts.posts)}} Posts</figure>
          </div>
        </section>
      </div>
    """


