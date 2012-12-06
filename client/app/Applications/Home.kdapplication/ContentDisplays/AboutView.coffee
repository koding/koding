class AboutView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "about about-pane content-display"

    super options, data

    @back   = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : =>
        @getSingleton("contentDisplayController").emit "ContentDisplayWantsToBeHidden", @

  viewAppended:->

    super
    @putTeam()

  pistachio:->

    """
      <h2 class="sub-header">{{> @back}}</h2>
      <div class="about-page-left">
        <h2>About Koding</h2>
        <p class="about-sub">Koding is a developer community and cloud development environment where developers come together and code – in the browser… with a real development server to run their code.</p>
        <p>We’ve created a platform for developers where getting started is easy. Developers can work, collaborate, write and run apps without jumping through hoops and spending hard earned money.</p>
        <h3>How We Started</h3>
        <p>Koding started with two brothers… Myself (Devrim) &amp; Sinan coming together to give something back to the developer community.</p>
        <p>How did it start? Well, in the summer of 2008—7 years later than the last time we had developed a website—I just wanted to make a website and learn PHP at the same time… maybe install WordPress and do a blog. I hoped that things would be much faster and smarter than it was 7 years before. Once I got started, I quickly realized that not much had changed.</p>
        <h3>Barriers To Entry AKA <span>Developer Hell</span></h3>
        <p>I had to download the zip, I had to unzip it, (it was even more fun with tar.gz). I had to have FTP running on the server and an FTP client on my local computer, I had to upload those files after I changed config.inc, I had to have the correct database setup and wait until I got everything uploaded (waiting for FTP to finish a thousand files was the best time to meditate), not to mention, user permissions, apache settings, SVN setup, dealing with hosting companies, going through all sorts of nonsese... and worst of all, at every turn being asked for money. Need hosting? BUY NOW! $2 for crappy shared hosting, $50 for a less crappy VPS, Not enough? pay $100 for a dedicated server, learn to be a sys admin and dedicate yourself to those sort of problems problems. Call support if your dedication isn’t enough and pay little more. Oh I almost forgot, we just wanted to code right? So you need a code editor? Prices are from $50 to $500. Don’t we all love notepad?</p>
        <p>We thought this was unfair as much as it was stupid. Unfair because, we ran an outsourcing company for years, and we saw that what you call 'affordable' here, is not affordable 'there'. What you call a 'cool gadget' here, is an unreachable dream to many over there. You know where. Stupid because <em>the current process of getting web apps to run is far behind what can be achieved with today's technology</em>.</p>
        <h3>Making The Web A Better Place</h3>
        <p>So… if open source is about collaboration and giving developers equal chances, we thought, If we could first remove those stupid barriers, uploading, downloading, setting up servers; secondly and most importantly, we felt obliged to do something for those who can only spare a few bucks a month to send it to their families.</p>
        <p>I wanted to have a tool like this for myself too. And we decided to get this done.</p>
        <p>And here we are today with Koding. We hope while you enjoy using the system, you will take a moment to think, the difference we all can make for those of us who do not have the resources to make their dreams come true.</p>
        <h3>Let’s Be Free</h3>
        <p>Koding was originally seeded and funded by us up until this summer, when we met some amazing people who shared our dream of a better world for developers.</p>
        <p>Our plan is this: our free accounts will always be free, and be enough for every developer to go out, develop and make money without worrying about how to get crack software or how to pay for legal software. Our free accounts are not designed to frustrate developers so that they end up paying or leaving; They are designed to make them happy and stay here as long as they want.</p>
        <p>As we build in more features, we'll eventually have some premium features for companies to build teams and have their own Koding as well as the ability to purchase more resources. We will only require a paid-plan if you want to have a lot of storage and traffic, private domains etc. This is a project that will ask companies to pay fees per user and it will stay free for developers forever with the features that developers need to get their apps running.</p>
        <p>Welcome to our community!</p>
        <p><strong>Devrim Yasar</strong>Co-Founder and CEO</p>
        <p>-on behalf of the Koding team!</p>
      </div>
      <div class="about-page-right"></div>
      <div class="location-wrapper">
        <div class="location">
          <p class="loc-first">
            We're located at <strong>SOMA</strong> district in <strong>San Francisco, California.</strong>
          </p>
          <address>
            <span class='icon fl'></span>
            <p class='right-overflow'>
              <strong>Koding, Inc.</strong>
              <a href="http://goo.gl/maps/XGWr" target="_blank">
                153 Townsend, Suite 9072<br>
                San Francisco, CA 94107
              </a>
            </p>
          </address>
        </div>
        <div class="first-line"></div>
        <div class="second-line"></div>
      </div>
    """

  putTeam:->

    for memberData in @theTeam
      member = new AboutMemberView {}, memberData
      @addSubView member, ".about-page-right"

  theTeam:
    [
        name      : 'Devrim Yasar'
        nickname  : 'devrim'
        job       : 'Co-Founder &amp; CEO'
        image     : '../images/people/devrim.jpg'
      ,
        name      : 'Sinan Yasar'
        nickname  : 'sinan'
        job       : 'Co-Founder &amp; Chief UI Engineer'
        image     : '../images/people/sinan.jpg'
      ,
        name      : 'Chris Thorn (w/ Milo)'
        nickname  : 'chris'
        job       : 'Director of Engineering'
        image     : '../images/people/chris.jpg'
      ,
        name      : 'Aleksey Mykhailov'
        nickname  : 'aleksey-m'
        job       : 'Sys Admin &amp; node.js Developer'
        image     : '../images/people/aleksey.jpg'
      ,
        name      : 'Gökmen Göksel'
        nickname  : 'gokmen'
        job       : 'Software Engineer'
        image     : '../images/people/gokmen.jpg'
      # ,
      #   name      : 'Son Tran-Nguyen'
      #   nickname  : 'sntran'
      #   job       : 'Software Engineer'
      #   image     : '../images/people/son.jpg'
      ,
        name      : 'Arvid Kahl'
        nickname  : 'arvidkahl'
        job       : 'Software Engineer'
        image     : '../images/people/arvid.jpg'
      ,
        name      : 'Richard Musiol'
        nickname  : 'neelance'
        job       : 'Software Engineer'
        image     : '../images/people/richard.jpg'
    ]


class AboutMemberView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'teammember'

    super options, data

    # @memberLink = new ProfileLinkView null, null

  viewAppended: JView::viewAppended

  pistachio:->

    {name, job, image, nickname} = @getData()

    """
      <img src="#{image}" />
      <p>
        <a href='/#{nickname}'><strong>#{name}</strong></a>
        #{job}
      </p>
    """










