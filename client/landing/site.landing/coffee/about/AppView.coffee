JView         = require './../core/jview'
AboutListItem = require './aboutlistitem'
JobsView      = require './jobsview'
FooterView    = require './../home/footerview'
TEAM          = require './team'
module.exports = class AboutView extends JView

  constructor:->

    @jobsView   = new JobsView

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
            #{TEAM.active.length} Koders
          </div>
          <div class='lines'>
            <i></i>
            <h6>VMs spinned up</h6>
            15,000,000+
          </div>
        </aside>
      </div>
    </section>
    {{> @footer}}
    """
