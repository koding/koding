class AboutView extends KDView

  constructor:->
    @activeController = new KDListViewController
      view        : new KDListView
        itemClass : AboutListItem
        type      : 'team'
        tagName   : 'ul'
      scrollView  : no
      wrapper     : no
    ,
      items       : KD.team.active

    @founders = new FoundersView
    @memberList = @activeController.getView()

    @logoPackButton = new KDCustomHTMLView
      tagName       : 'a'
      attributes    :
        href        : '/a/images/koding-logo.pdf'
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

    @once 'viewAppended', => document.body.scrollTop = 0



  viewAppended: JView::viewAppended

  pistachio : ->
    """
      {{> @founders}}
      <section class="about-company">
        <div class='wrapper'>
          <article>
            <h2>Story & Culture</h2>
            <h4>When I say Koding, I mean coding</h4>
            <p>
              ...made the first site back in 2009, it was our first attempt to make something totally on our own. Sinan and I, had no money and had no intentions of making money using this thing. We made it for ourselves and for everybody else who was suffering trying to learn stuff, getting lost configuring servers. We launched a version that would work for a few people. When we opened it however, we saw hundreds of people rushing in overnight, <a href='http://blog.koding.com/2012/06/we-want-to-date-not-hire/' target='_blank'>read more</a>...
            </p>
          </article>
          <aside class="clearfix">
            <div class="based">
              <i></i>
              <h6>Based</h6>
              San Francisco
            </div>
            <div class="talents">
              <i></i>
              <h6>Talent</h6>
              #{KD.team.active.length} Koders
            </div>
            <div class="lines">
              <i></i>
              <h6>VMs spinned up</h6>
              1,000,000+
            </div>
          </aside>
          <cite>photo by - <a href='http://www.tidyclub.com/' target='_blank'>Isaak Dury</a></cite>
        </div>
      </section>
      <section class="member-list">
        <div class='wrapper'>
          <h2>The A-Team</h2>
          <h4>Look at them geniuses <cite>*in order of appearance</cite></h4>
          {{> @memberList}}
        </div>
      </section>
      <section class="press-kit">
        <div class='wrapper'>
          <h2>Press Kit</h2>
          <h4>Resources for brand enthusiasts</h4>
          {{> @logoPackButton}}
          {{> @fontPackButton}}
        </div>
      </section>
      <section class="careers">
        <div class='wrapper'>
          <h2>Careers</h2>
          <h4>Shoot us an <a href='mailto:hr@koding.com?subject=Koding%20needs%20me!' target='_self'>email</a> if you think you should be a part of Koding!</h4>
        </div>
      </section>
    """

class FoundersView extends JView

  constructor : (options = {}, data) ->

    options.tagName  = 'section'
    options.cssClass = 'founders clearfix'

    super options, data

    # @devrim = new KDCustomHTMLView
    #   tagName    : 'img'
    #   cssClass   : 'devrim'
    #   attributes :
    #     src      : '/a/team/devrim.jpg'

    # @sinan = new KDCustomHTMLView
    #   tagName    : 'img'
    #   cssClass   : 'sinan'
    #   attributes :
    #     src      : '/a/team/sinan.jpg'

  pistachio : ->

    # <aside>
    #   {{> @devrim}}
    #   {{> @sinan}}
    # </aside>
    """
    <div class='wrapper'>
      <h2>About <i>Koding</i></h2>
      <h4>Social development in your browser</h4>
      <article>
        Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping through hoops and spending unnecessary money.
      </article>
    </div>
    """


class AboutListItem extends KDListItemView

  constructor:(options={}, data)->

    options.tagName = 'li'
    options.type    = 'team'

    super options, data

    {username} = @getData()
    @avatar    = new AvatarView
      origin   : username
      size     : width : 160

    @link      = new CustomLinkView
      cssClass : 'profile'
      href     : "/#{username}"
      title    : "@#{username}"

    @title     = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'title'
      partial  : @getData().title


  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <figure>
      {{> @avatar}}
    </figure>
    <figcaption>
      {{> @link}}
      {{> @title}}
    </figcaption>
    """

