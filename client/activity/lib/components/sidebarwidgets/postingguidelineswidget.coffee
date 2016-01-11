kd         = require 'kd'
React      = require 'kd-react'
Link       = require 'app/components/common/link'
classnames = require 'classnames'

module.exports = class PostingGuideLinesWidget extends React.Component

  constructor: (props) ->

    super

    @state = { isExpanded: no }


  showMoreClick: (event) ->

    kd.utils.stopDOMEvent event

    @setState isExpanded: yes


  hideInfoClick: (event) ->

    kd.utils.stopDOMEvent event

    @setState isExpanded: no


  getWrapperClassName: -> classnames
    'expanded'               : @state.isExpanded
    'ActivityGuideWidget'    : yes
    'ActivitySidebar-widget' : yes


  render: ->

    <div className={@getWrapperClassName()}>
      <h3>Posting Guidelines</h3>
      <div>
        <ol>
          <li>
            Take a look at&nbsp;
            <a
              href='http://learn.koding.com'
              target='_blank'>Koding University</a>
            &nbsp; in case your question is of the category
            “how do I…” Chances are high that have a handy guide for you.
          </li>
          <li>
            Ask your questions in a way that would make it easy for others to answer.
            Follow “question asking techniques”&nbsp;
            <a href='http://codeblog.jonskeet.uk/2010/08/29/writing-the-perfect-question/' target='_blank'>here</a>.
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
            Report any abuse to&nbsp;
            <a href='mailto:abuse@koding.com'>abuse@koding.com</a>.
          </li>
          <li>
            Don’t share private info (email address, phone number, etc.)
          </li>
          <li>
            Use Markdown whenever possible (posting code fragments, links, images, etc.)
            Our handy Markdown guide can be found&nbsp;
            <a href='http://learn.koding.com/guides/markdown/' target='_blank'>here</a>.&nbsp;
            Preview your Markdown before posting using the M↓ button.
          </li>
          <li>
            When posting code, only post relevant portions. A good rule of thumb is
            not to exceed 10-15 lines.
          </li>
          <li>
            Don’t ask for the Koding support team to help via a post here. Instead,
            hit us up at&nbsp;
            <a href='mailto:support@koding.com'>support@koding.com</a>.&nbsp;
            We monitor that inbox constantly.
          </li>
        </ol>
      </div>
      <Link
        className='ActivityGuideWidget-readMore'
        onClick={@bound 'showMoreClick'}>read more...</Link>
      <Link
        className='ActivityGuideWidget-hideInfo'
        onClick={@bound 'hideInfoClick'}>hide info...</Link>
    </div>
