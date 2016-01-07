kd = require 'kd'
ActivityBaseWidget = require './activitybasewidget'
CustomLinkView = require 'app/customlinkview'


module.exports = class ActivityGuideWidget extends ActivityBaseWidget

  constructor: (options = {}, data) ->

    options.cssClass    = kd.utils.curry 'posting-guide-widget', options.cssClass

    super options, data

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
            “how do I…” Chances are high that we already have a handy guide for you.
          </li>
          <li>
            Ask your questions in a way that would make it easy for others to answer.
            Follow “question asking techniques” <a href='http://codeblog.jonskeet.uk/2010/08/29/writing-the-perfect-question/' target='_blank'>here</a>.
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
            Report any abuse to <a href='mailto:abuse@koding.com'>abuse@koding.com</a>.
          </li>
          <li>
            Don’t share private info (email address, phone number, etc.)
          </li>
          <li>
            Use Markdown whenever possible (posting code fragments, links, images, etc.)
            Our handy Markdown guide can be found <a href='http://learn.koding.com/guides/markdown/' target='_blank'>here</a>. Preview your Markdown before posting using the M↓ button.
          </li>
          <li>
            When posting code, only post relevant portions. A good rule of thumb is
            not to exceed 10-15 lines.
          </li>
          <li>
            Don’t ask for the Koding support team to help via a post here. Instead,
            hit us up at <a href='mailto:support@koding.com'>support@koding.com</a>. We monitor that inbox constantly.
          </li>
        </ol>
      </p>
      {{> @readMoreLink}}{{> @readLessLink}}
    """
