SubscribeForm    = require './subscribeformview'
CustomLinkView   = require './../core/customlinkview'

{
  judges   : JUDGES
  partners : PARTNERS
} = KD.campaignStats.campaign

VIDEO_URL        = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.webm'
VIDEO_URL_MP4    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.mp4'
VIDEO_URL_OGG    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.ogv'

RESULTS = [
  {
    category              : 'Top Hackers'
    teams                 : [

      {
        teamName          : 'Team WunderBruders'
        description       : 'Theme: Introducing software development to a beginner (games!)'
        previewImage      : 'wunder-bruders.png'
        readme            : 'http://github.com/edgarjcfn/koding-spy'
        projectUrl        : 'http://edgarjcfn.koding.io/Lucy'
        members           : [
          {
            name          : 'edgarjcfn'
            avatar        : 'https://gravatar.com/avatar/962795099dbaff61ffa3c8474f09001d?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'de'
          },
          {
            name          : 'ziro9476'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'de'
          }
        ]
      },
      {
        teamName          : 'Team Coddee Break'
        description       : 'Theme: Problems facing our planet, explained using interactive data visualization. (e.g. climate change, earthquakes, food/water waste, accessibility related issues, etc.)'
        previewImage      : 'coddee-break.png'
        readme            : 'https://github.com/koding/global.hackathon/blob/master/Teams/Coddee-Break/ABOUT.md'
        projectUrl        : 'http://kuzmaka.koding.io'
        members           : [
          {
            name          : 'kuzmaka'
            avatar        : 'https://koding.com/-/image/cache?endpoint=crop&grow=true&width=40&height=40&url=https%3A%2F%2Fkoding-client.s3.amazonaws.com%2Fuser%2Fkuzmaka%2Favatar-1418389518067'
            nationality   : 'ua'
          },
          {
            name          : 'prineside'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ua'
          }
        ]
      },
      {
        teamName          : 'Team WaterPistols'
        description       : 'Theme: HTML5 games that are educational and learning oriented. (multiplayer preferred)'
        previewImage      : 'water-pistols.png'
        readme            : 'https://github.com/koding/global.hackathon/tree/master/Teams/WaterPistols'
        projectUrl        : 'http://andreilaza.koding.io/index.html'
        members           : [
          {
            name          : 'undemian'
            avatar        : 'https://gravatar.com/avatar/bd3a5df76e4e8f592db7cd75764e5a52?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'ro'
          },
          {
            name          : 'andreilaza'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ro'
          },
          {
            name          : 'depeshutz'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ro'
          },
          {
            name          : 'claudiuthefilip'
            avatar        : 'https://gravatar.com/avatar/838667f559b96043acc15f39b79bcee2?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'ro'
          }
        ]
      }
    ]
  },
  {
    category              : 'Student Hackers'
    teams                 : [

      {
        teamName          : 'Team Unknown Exception'
        description       : 'Theme: No one reads the fine print (ie TOS, EULA, legal documents) anymore yet every site has them. Devise a creative/interactive solution.'
        previewImage      : 'unknown-exception.png'
        readme            : 'https://github.com/koding/global.hackathon/blob/master/Teams/UnknownException/ABOUT.md'
        projectUrl        : 'http://ukkkb6776eaa.kp1234.koding.io'
        members           : [
          {
            name          : 'kp1234'
            avatar        : 'https://gravatar.com/avatar/4c8809e997417b617b6d075bc7d8ca56?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'ca'
          }
        ]
      },
      {
        teamName          : 'Team CE'
        description       : 'Theme: No one reads the fine print (ie TOS, EULA, legal documents) anymore yet every site has them. Devise a creative/interactive solution.'
        previewImage      : 'ce.png'
        readme            : 'https://github.com/koding/global.hackathon/blob/master/Teams/CE/ABOUT.md'
        projectUrl        : 'http://pwstegman.koding.io/'
        members           : [
          {
            name          : 'pwstegman'
            avatar        : 'https://koding.com/-/image/cache?endpoint=crop&grow=true&width=40&height=40&url=https%3A%2F%2Fkoding-client.s3.amazonaws.com%2Fuser%2Fpwstegman%2Favatar-1418499021470'
            nationality   : 'us'
          },
          {
            name          : 'fwilson'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          }
        ]
      },
      {
        teamName          : 'Team Carter'
        description       : 'Theme: Introducing software development to a beginner (games!)'
        previewImage      : 'team-carter.png'
        readme            : 'https://github.com/koding/global.hackathon/blob/master/Teams/TeamCarter/ABOUT.md'
        projectUrl        : 'http://pokescript.cartr.koding.io'
        members           : [
          {
            name          : 'cartr'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ca'
          }
        ]
      }

    ]
  },
  {
    category              : 'Apprentice Hackers'
    teams                 : [

      {
        teamName          : 'Team BitsPlease'
        description       : 'Theme: HTML5 games that are educational and learning oriented. (multiplayer preferred)'
        previewImage      : 'bits-please.png'
        readme            : 'https://github.com/koding/global.hackathon/tree/master/Teams/BitsPlease'
        projectUrl        : 'http://numero.phantastik.koding.io'
        members           : [
          {
            name          : 'claudiuthefilip'
            avatar        : 'https://gravatar.com/avatar/838667f559b96043acc15f39b79bcee2?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'ca'
          },
          {
            name          : 'phantastik'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ca'
          },
          {
            name          : 'benwang'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ca'
          },
          {
            name          : 'lyamelia'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'ca'
          },
          {
            name          : 'mattpua'
            avatar        : 'https://gravatar.com/avatar/2a715863bf84527c30ab9b8bff4f8777?size=40&d=https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png&r=g'
            nationality   : 'ca'
          }
        ]
      },
      {
        teamName          : 'Team Average Joes'
        description       : 'Theme: HTML5 games that are educational and learning oriented. (multiplayer preferred)'
        previewImage      : 'average-joes.png'
        readme            : 'https://github.com/koding/global.hackathon/blob/master/Teams/AverageJoes/ABOUT.md'
        projectUrl        : 'http://ulkkba22d741.lukebarwikowski.koding.io/'
        members           : [
          {
            name          : 'lbarwiko'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          },
          {
            name          : 'Lantieau3'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          },
          {
            name          : 'nmart'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          },
          {
            name          : 'datCordLife'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          }
        ]
      },
      {
        teamName          : 'Team MoeABM'
        description       : 'Theme: No one reads the fine print (ie TOS, EULA, legal documents) anymore yet every site has them. Devise a creative/interactive solution.'
        previewImage      : 'moeabm.png'
        readme            : 'https://github.com/moeabm/global.hackathon/blob/master/Teams/MoeABM/ABOUT.md'
        projectUrl        : 'http://umkk6903efde.moeabm.koding.io/hackathon/'
        members           : [
          {
            name          : 'Moeabm'
            avatar        : 'http://i0.wp.com/koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.40.png'
            nationality   : 'us'
          }
        ]
      }
    ]
  }
]


module.exports = class HomeViewResults extends KDView

  constructor: (options = {}, data)->

    super options, data

    @setPartial @partial()
    @createSubscribeForms()
    @createResults()
    @createPartners()
    @createJudges()


  createPartners: ->

    for name, {img, url, prize} of PARTNERS

      image = new KDCustomHTMLView
        tagName    : 'a'
        cssClass   : 'sponsor'
        attributes :
          href     : url
          target   : '_blank'
        partial    : "<img src='#{img}' alt='#{name}' \>"

      @addSubView image, 'section.sponsors .inner-container'


  createSubscribeForms: ->

    @topSubscribeForm    = new SubscribeForm
    @bottomSubscribeForm = new SubscribeForm

    @addSubView @topSubscribeForm, '.subscribe-form-wrapper.top'
    @addSubView @bottomSubscribeForm, '.subscribe-form-wrapper.bottom'


  createJudges: ->

    for name, content of JUDGES
      view = new KDCustomHTMLView
        cssClass    : 'judge'

      view.addSubView new KDCustomHTMLView
        tagName     : 'figure'
        attributes  :
          style     : "background-image:url(#{content.imgUrl});"

      view.addSubView new CustomLinkView
        cssClass    : 'info'
        title       : name
        href        : content.linkedIn
        target      : '_blank'

      view.addSubView new KDCustomHTMLView
        cssClass    : 'details'
        partial     : "<span>#{content.title}</span><cite>#{content.company}</cite>"

      @addSubView view, 'section.judges .inner-container'


  createResults: ->

    resultsContainer = 'section.results .inner-container'
    rankNames        = ['first', 'second', 'third']

    RESULTS.forEach (result) =>
      {category, teams} = result

      categorySection = new KDCustomHTMLView
        cssClass : "category"

      categorySection.addSubView new KDCustomHTMLView
        tagName   : 'h3'
        partial   : category
        cssClass  : "#{KD.utils.slugify category}"

      teams.forEach (team, rank) ->
        rankName      = rankNames[rank]
        nationalities = []

        {previewImage, teamName, description, members, readme, projectUrl} = team

        categorySection.addSubView teamView = new KDCustomHTMLView
          cssClass    : "team #{rankName} clearfix"

        teamView.addSubView new KDCustomHTMLView
          tagName     : 'figure'
          cssClass    : 'team-preview-image'
          attributes  :
            'style'   : "background-image: url(./a/site.hackathon/images/project-previews/#{previewImage});"

        teamView.addSubView title = new KDCustomHTMLView
          tagName     : 'h4'
          cssClass    : 'team-title'
          partial     : "<a href='#{readme}' target='_blank'>#{teamName}</a>"

        title.addSubView flags = new KDCustomHTMLView
          cssClass    : 'flags'

        teamView.addSubView new KDCustomHTMLView
          tagName     : 'p'
          cssClass    : 'team-description'
          partial     : description

        teamView.addSubView heads = new KDCustomHTMLView
          cssClass    : 'team-heads'

        members.forEach (member) ->
          {nationality, name, avatar} = member

          if nationalities.indexOf(nationality) is -1
          then nationalities.push nationality

          heads.addSubView new KDCustomHTMLView
            tagName   : 'figure'
            cssClass  : 'member-head'
            attributes  :
              'style'   : "background-image: url(#{avatar});"

        nationalities.forEach (nationality) ->
          flags.addSubView new KDCustomHTMLView
            tagName     : 'figure'
            cssClass    : "flag #{nationality}"
            attributes  :
              'style'   : "background-image: url(./a/site.hackathon/images/flags/#{nationality}.png);"

      @addSubView categorySection, resultsContainer


  viewAppended: ->

    video = document.getElementById 'bgVideo'
    if window.innerWidth < 680
      video.parentNode.removeChild video
    else
      video.addEventListener 'loadedmetadata', ->
        @currentTime = 8
        @playbackRate = .7
        KD.utils.wait 3000, -> video.classList.add 'in'
      , no


  partial: ->
    """
      <header class="main-header">
        <a href="http://koding.com" target='_blank' class="logo"></a>
      </header>

      <section class="intro">
        <video id="bgVideo" autoplay loop muted>
          <source src="#{VIDEO_URL}" type="video/webm"; codecs=vp8,vorbis">
          <source src="#{VIDEO_URL_OGG}" type="video/ogg"; codecs=theora,vorbis">
          <source src="#{VIDEO_URL_MP4}">
        </video>
        <figure class="cup-figure"></figure>
        <h1>Q4 2014 VIRTUAL GLOBAL HACKATHON</h1>
        <h2>WINNERS ANNOUNCED</h2>
        <div class="subscribe-form-wrapper clearfix top"></div>
      </section>

      <section class="results std-section" id="winners">
        <div class="inner-container clearfix"></div>
      </section>


      <section class="prizes std-section" id="prizes">
        <div class="inner-container clearfix">
          <h3 class="section-title">FANTASTIC PRIZES</h3>
          <div class="prize-box">
            <i class="top-hackers"></i>
            <h4>TOP HACKERS</h4>
            <ul>
              <li><span>First Prize</span> $8,000</li>
              <li><span>Second Prize</span> $4,000</li>
              <li><span>Third Prize</span> $2,000</li>
            </ul>
          </div>
          <div class="prize-box">
            <i class="student-hackers"></i>
            <h4>STUDENT HACKERS</h4>
            <ul>
              <li><span>First Prize</span> $1,500</li>
              <li><span>Second Prize</span> $1,000</li>
              <li><span>Third Prize</span> $500</li>
            </ul>
          </div>
          <div class="prize-box">
            <i class="apprentice-hackers"></i>
            <h4>APPRENTICE HACKERS</h4>
            <ul>
              <li><span>First Prize</span> $1,200</li>
              <li><span>Second Prize</span> $800</li>
              <li><span>Third Prize</span> $500</li>
            </ul>
          </div>
          <div class="note">
            Please note: Student hackers are not precluded from submitting
            their project for the Top Hacker category.
          </div>
        </div>
      </section>

      <section class="themes std-section" id="themes">
        <div class="inner-container clearfix">
          <h3 class="section-title">REAL THEMES</h3>
          <ul>
            <li>Problems facing our planet, explained using interactive data
                visualization. (e.g. climate change, earthquakes, food/water waste,
                accessibility related issues, etc.)</li>
            <li>Introducing software development to a beginner (games!)</li>
            <li>No one reads the fine print (ie TOS, EULA, legal documents) anymore
                yet every site has them. Devise a creative/interactive solution.</li>
            <li>HTML5 games that are educational and learning oriented. (multiplayer preferred)</li>
            <li>Challenges associated with real time communication and translation
                (Star Trek universal translator anyone?)</li>
          </ul>
        </div>
      </section>

      <section class="sponsors std-section" id="sponsors">
        <div class="inner-container clearfix">
          <h3 class="section-title">AMAZING SPONSORS</h3>

        </div>
      </section>

      <section class="judges std-section" id="judges">
        <div class="inner-container clearfix">
          <h3 class="section-title">AWESOME JUDGES</h3>
        </div>
      </section>

      <section class="subscribe">
        <div class="inner-container clearfix">
          <div class="subscribe-form-wrapper clearfix bottom"></div>
        </div>
      </section>

      <footer class="main-footer">
        <div class="inner-container clearfix">
          2014 © Koding Hackathon
          <nav>
            <a href="http://koding.com/About">About</a>
            <a href="http://blog.koding.com">Blog</a>
          </nav>
        </div>
      </footer>
    """
