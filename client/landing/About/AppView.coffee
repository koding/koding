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

    @randomTeamMember = new RandomTeamMemberView
    @memberList = @activeController.getView()

    @logoPackButton = new KDButtonView
      title         : "Download Logo Pack"
      style         : "solid green"
      icon          : yes

    @fontPackButton = new KDButtonView
      title         : "Download Font Pack"
      style         : "solid green"
      icon          : yes

    super

  viewAppended: JView::viewAppended

  pistachio : ->
    """
      {{> @randomTeamMember}}
      <section class="about-company">
        <article>
          <h2>Story & Culture</h2>
          <h4>When I say Koding, I mean Coding</h4>
          <p>
            Duis lorem elit, placerat non consequat ut, aliquet ac purus. Nunc nec est quis erat blandit vestibulum at id orci. Aliquam feugiat convallis libero, id ullamcorper nulla blandit quis. Proin sodales suscipit mi, id accumsan risus convallis a. Duis congue vitae lectus vel ultricies. Vivamus eleifend eros sodales purus dignissim sagittis. Sed volutpat dictum mi ultrices luctus. Integer vitae varius eros, quis tempus lectus.
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
            25 Geniuses
          </div>
          <div class="lines">
            <i></i>
            <h6>Lines of Code</h6>
            21654789
          </div>
        </aside>
      </section>
      <section class="member-list">
        <h2>The A-Team</h2>
        <h4>Look at them geniuses</h4>
        {{> @memberList}}
      </section>
      <section class="press-kit">
        <h2>Press Kit</h2>
        <h4>Resources for brand enthusiasts</h4>
        {{> @logoPackButton}}
        {{> @fontPackButton}}
      </section>
    """

class RandomTeamMemberView extends JView
  constructor : (options = {}, data) ->
    options.cssClass = "random-team-member clearfix"

    super options, data

  getRandomTeamMember : ->
    team  = KD.team.active
    index = KD.utils.getRandomNumber team.length-1, 0

    log team[index]

    team[index]

  pistachio : ->
    {username, title} = @getRandomTeamMember()
    @avatar    = new AvatarView
      origin   : username
      size     : width : 300

    @link      = new ProfileLinkView origin : username

    """
      {{> @avatar}}
      <section>
        {{> @link}}
        <cite>#{title}</cite>
        <article>
          Duis lorem elit, placerat non consequat ut, aliquet ac purus. Nunc nec est quis erat blandit vestibulum at id orci. Aliquam feugiat convallis libero, id ullamcorper nulla blandit quis. Proin sodales suscipit mi, id accumsan risus convallis a. Duis congue vitae lectus vel ultricies. Vivamus eleifend eros so-
        </article>
      </section>
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

    @link      = new ProfileLinkView origin : username


  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <figure>
      {{> @avatar}}
    </figure>
    <figcaption>
      {{> @link}}
      {cite{ #(title)}}
    </figcaption>
    """

