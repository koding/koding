JView = require './../core/jview'

module.exports = class AboutView extends JView

  constructor:->

    @activeController = new KDListViewController
      view        : new KDListView
        cssClass  : 'clearfix'
        itemClass : AboutListItem
        type      : 'team'
        tagName   : 'ul'
      scrollView  : no
      wrapper     : no
    ,
      items       : KD.team.active

    @memberList = @activeController.getView()

    @jobsView   = new JobsView

    @logoPackButton = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : 'https://koding-cdn.s3.amazonaws.com/brand/koding-logo.pdf'
        target      : '_blank'
      partial       : "<span class='icon'></span>Download Logo Pack"
      cssClass      : "solid green kdbutton"
      icon          : yes

    @fontPackButton = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : 'http://www.google.com/fonts/specimen/Ubuntu'
        target      : '_blank'
      partial       : "<span class='icon'></span>Download Font Pack"
      cssClass      : "solid green kdbutton"
      icon          : yes

    super

    @once 'viewAppended', -> document.body.scrollTop = 0

    @footer = new FooterView

  pistachio : ->
    """
    <section class='about-company'>
      <div class='wrapper'>
        <article>
          <h2>Social development in your browser</h2>
          <p>Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping through hoops and spending unnecessary money.</p>
        </article>
        <article>
          <h2>Story & Culture</h2>
          <p>We made the first site back in 2009, it was our first attempt to make something totally on our own. Sinan and I, had no money and had no intentions of making money using this thing. We made it for ourselves and for everybody else who was suffering trying to learn stuff and getting lost configuring servers. We planned a version that would work for a few people. However when we launched it, we saw hundreds of people rushing in overnight…</p>
          <a href='http://blog.koding.com/2012/06/we-want-to-date-not-hire/' target='_blank'>Read more...</a>
        </article>
        <aside class='clearfix'>
          <div class='based'>
            <i></i>
            <h6>Based</h6>
            San Francisco
          </div>
          <div class='talents'>
            <i></i>
            <h6>Talent</h6>
            #{KD.team.active.length} Koders
          </div>
          <div class='lines'>
            <i></i>
            <h6>VMs spinned up</h6>
            15,000,000+
          </div>
        </aside>
      </div>
    </section>
    <section class='member-list'>
      <div class='wrapper'>
        <h2>Koding. <span>The Crew</span></h2>
        <h4>In order of appearance</h4>
        {{> @memberList}}
      </div>
    </section>
    <section class='careers' id='jobs'>
      <div class='wrapper'>
        <h2>Koding. <span>Jobs</span></h2>
        <h4>If you think your picture is missing above...</h4>
        {{> @jobsView }}
      </div>
    </section>
    <section class='press-kit'>
      <div class='wrapper'>
        <h2>Press Kit</h2>
        <h4>Resources for brand enthusiasts</h4>
        {{> @logoPackButton}}
        {{> @fontPackButton}}
      </div>
    </section>
    {{> @footer}}
    """
