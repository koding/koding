class ActivityGuideWidget extends JView
  constructor: (options = {}) ->
    options.cssClass    = 'posting-guide-widget'
    super options

    @readLessLink       = new CustomLinkView
      title             : 'hide info...'
      cssClass          : 'read-more-link hidden'
      click             : =>
        @unsetClass 'expand'
        @readMoreLink.show()
        @readLessLink.hide()

    @readMoreLink       = new CustomLinkView
      title             : 'read more...'
      cssClass          : 'read-more-link'
      click             : =>
        @setClass 'expand'
        @readMoreLink.hide()
        @readLessLink.show()


  pistachio : ->
    """
      <h3>Posting Guidelines</h3>
      <p>
        <ol>
          <li>
            Take a look at <a href='http://learn.koding.com' target='_blank'>Koding University</a> in case your question is of the category
            “how do I…” Chances are high that we have a handy dandy guide for you.
          </li>
          <li>
            Ask your questions in a way that would make it easy for others to answer.
            (hint: ask the question as if you were trying to answer it). More awesome
            “question asking techniques” <a href='http://codeblog.jonskeet.uk/2010/08/29/writing-the-perfect-question/' target='_blank'>here</a>.
          </li>
          <li>
            Posts that contain any of these will be mercilessly deleted by the
            moderators and your account could be banned:
            <ol>
              <li>abusive, racist or derogatory posts</li>
              <li>meaningless posts</li>
              <li>referral links</li>
            </ol>
          </li>
          <li>
            If someone answers your question with a relevant answer, be polite and
            thank them (or go the extra step and “like” them!).
          </li>
          <li>
            We all need to collaborate to keep the Koding community klean. Report
            any abuse to <a href='mailto:abuse@koding.com'>abuse@koding.com</a>. Fight back on any abuse!
          </li>
          <li>
            Don’t share private info (email address, phone number, etc.)
          </li>
          <li>
            Use Markdown whenever possible (postint code fragments, links, images, etc.)
            Our handy Markdown guide can be found <a href='http://learn.koding.com/guides/markdown/' target='_blank'>here</a>. Preview your Markdown before
            posting using the M↓ button.
          </li>
          <li>
            When posting code, only post relevant portions. A good rule of thumb is
            not to exceed 10-15 lines.
          </li>
          <li>
            Don’t ask for the Koding support team to help via a post here. Instead,
            hit us up at <a href='mailto:support@koding.com'>support@koding.com</a>. We monitor that inbox constantly
            (visualize a Koder positioned like a Hawk, watching that inbox).
          </li>
          <li>
            If you think you can remotely help someone, expert or not, just <a href='https://www.youtube.com/watch?v=RBMdsSwNZ9M' target='_blank'>do it</a>.
          </li>
        </ol>

        <h4>Tools we recommend</h4>
        <ol>
          <li>For screen grabs: <a href='http://monosnap.com' target='_blank'>Monosnap</a></li>
          <li>For posting code: <a href='https://gist.github.com/' target='_blank'>Gist</a></li>
          <li>For executables: <a href='http://ideone.com/' target='_blank'>IDEone</a></li>
          <li>For HTML, CSS and JS: <a href='http://jsfiddle.net/' target='_blank'>JSFiddle</a></li>
        </ol>
      </p>
      {{> @readMoreLink}}{{> @readLessLink}}
    """