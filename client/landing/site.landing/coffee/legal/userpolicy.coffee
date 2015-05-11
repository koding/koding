JView          = require './../core/jview'

module.exports = class UserPolicyView extends JView
  constructor: (options = {}) ->

    super options

  pistachio : ->
    """
    <div class='tos'>
      <p class='last-modified'>(last modified on May 5th, 2015)</p>

      <p>
        Your use of Koding (the &ldquo;Service&rdquo;) is subject to the following
        Acceptable Use Policy. If you are found to be in violation of our policies
        at any time, as determined by Koding in its sole discretion, we may warn
        you or suspend or terminate your account. Please note that we may change
        our Acceptable Use Policy at any time, and pursuant to the Service Terms,
        it is your responsibility to keep up-to-date with and adhere to the
        policies posted here. All capitalized terms used herein have the meanings
        stated in the Terms, unless stated otherwise.
      </p>

      <p>
        <span class='s1'><b>Prohibited Content</b></span><br />
        The Content displayed and/or processed through your Application or other
        web site utilizing the Service shall not contain any of the following
        types of content:
      </p>

      <ul class='numbered-list'>
        <li>
          Content that infringes a third party&rsquo;s rights (e.g., copyright)
          according to applicable law;
        </li>

        <li>
          Excessively profane content;
        </li>

        <li>
          Hate-related or violent content;
        </li>

        <li>
          Content advocating racial or ethnic intolerance;
        </li>

        <li>
          Content intended to advocate or advance computer hacking or cracking;
        </li>

        <li>
          Gambling;
        </li>

        <li>
          Drug paraphernalia;
        </li>

        <li>
          Phishing;
        </li>

        <li>
          Malicious content;
        </li>

        <li>
          Any type of proxy services including but not exclusively VPN servers, TOR servers, etc.
        </li>

        <li>
          BitTorrenting or Filesharing;
        </li>

        <li>
          Run any software that interfaces with an IRC (Internet Relay Chat)
          network.
        </li>

        <li>
          Run any gaming servers such as Battlefield 3, MineCraft, Counter-Strike
          etc.
        </li>

        <li>
          Mining/Generating Crypto Currencies including but not limited to
          BitCoin, DogeCoin, LiteCoin etc.;
        </li>

        <li>
          Use of any kind of distributed computing software, including but not
          limited to SETI@home, Node Zero and Folding@home
        </li>

        <li>
          Pornography and Sexually Explicit Content;
        </li>

        <li>
          Use of any kind of VOIP related software, including but not limited to Teamspeak,
          Asterisk, FreePBX;
        </li>

        <li>
          Other material, products or services that violate or encourage conduct
          that would violate any criminal laws, any other applicable laws, or any
          third-party rights;
        </li>

        <li>
          Other illegal activity, including without limitation illegal export of
          controlled substances or illegal software;
        </li>
      </ul>

      <p>
        In addition to (and/or as some examples of) the violations described in
        our Terms of Service, you may not and may not allow any third party, including your
        End Users, to:
      </p>

      <ul class='numbered-list'>
        <li>
          Generate or facilitate unsolicited commercial email (&ldquo;spam&rdquo;).
          Such activity includes, but is not limited to:

          <ul class='lettered-list'>
            <li>
              sending email in violation of the CAN-SPAM Act or any other
              applicable anti-spam law
            </li>

            <li>
              imitating or impersonating another person or his, her or its email
              address, or creating false accounts for the purpose of sending spam
            </li>

            <li>
              data mining any web property (including Koding) to find email
              addresses or other user account information
            </li>

            <li>
              sending unauthorized mail via open, third-party servers
            </li>

            <li>
              sending emails to users who have requested to be removed from a
              mailing list
            </li>

            <li>
              selling, exchanging or distributing to a third party the email
              addresses of any person without such person&rsquo;s knowing and
              continued consent to such disclosure and
            </li>

            <li>
              sending unsolicited emails to significant numbers of email addresses
              belonging to individuals and/or entities with whom you have no
              preexisting relationship.
            </li>
          </ul>

        </li>

        <li>
          Send, upload, distribute or disseminate or offer to do the same with
          respect to any unlawful, defamatory, harassing, abusive, fraudulent,
          infringing, obscene, or otherwise objectionable content
        </li>

        <li>
          Intentionally distribute viruses, worms, defects, Trojan horses,
          corrupted files, hoaxes, or any other items of a destructive or
          deceptive nature
        </li>

        <li>
          Conduct or forward pyramid schemes and the like
        </li>

        <li>
          Transmit content that may be harmful to minors
        </li>

        <li>
          Illegally transmit another&rsquo;s intellectual property or other
          proprietary information without such owner&rsquo;s or licensor&rsquo;s
          permission
        </li>

        <li>
          Use the Service to violate the legal rights (such as rights of privacy
          and publicity) of others
        </li>

        <li>
          Promote or encourage illegal activity
        </li>

        <li>
          Interfere with other users&rsquo; enjoyment of the Service
        </li>

        <li>
          Sell, trade, resell or otherwise exploit the Service for any
          unauthorized commercial purpose
        </li>

        <li>
          Modify, adapt, translate, or reverse engineer any portion of the Service
        </li>

        <li>
          Remove any copyright, trademark or other proprietary rights notices
          contained in or on the Service
        </li>

        <li>
          Reformat or frame any portion of the web pages that are part of the
          Service&rsquo;s administration display
        </li>

        <li>
          Use the Service in connection with illegal peer-to-peer file sharing
        </li>

        <li>
          Display any content on the Service that contains any hate-related or
          violent content or contains any other material, products or services
          that violate or encourage conduct that would violate any criminal
          laws, any other applicable laws, or any third party rights
        </li>

        <li>
          Modify the Koding logo or any other Koding Marks or
        </li>

        <li>
          Use the Service, or any interfaces provided with the Service, to access
          any Koding product or service in a manner that violates the Terms or
          other terms and conditions for use of such Koding product or service.
        </li>
      </ul>

      <p>
        <b>Quotas and Limits</b><br />
        The Service is intended for development purposes and is not a production
        platform. We operate on shared servers and so we will rapidly suspend
        accounts that generate sustained high levels of load or use provided
        resources in a way that deteriorates the experience for other users.

        <ul class='narrow-list'>
          <li>Disk: 3GB per VM (or what your paid account comes with)</li>
          <li>Ram: 1GB per VM</li>
          <li>Network output: 7GB/week (free accounts), 14GB/week (paid accounts)</li>
        </ul>
      </p>

      Koding reserves the right to suspend or terminate accounts found in violation of these items with or without prior notice given and without liability.
      <p>
      In addition, Koding reserves the right to terminate unused VMs after a period of inactivity (Usually 45-60 days). Inactive accounts will
      be notified before any such action is taken.
      </p>

      <p>
        (This document is an adaptation of the Google App Engine Program Policies
        and the original work has been modified. Google, Inc. is not connected
        with and does not sponsor or endorse Koding or its use of the work.)
      </p>

    </div>
    """


