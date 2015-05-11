JView          = require './../core/jview'

module.exports = class UserPolicyView extends JView
  constructor: (options = {}) ->

    super options

  pistachio : ->
    """
    <div class='tos'>
      <p class='last-modified'>(last modified on May 5th, 2015)</p>

      <p class='p3'>
        If you believe that material available on the Koding Service
        (website, API, Marketplace), infringes on your copyright(s), please
        notify us by providing a DMCA notice. Upon receipt of a complete and valid
        notice, we will remove the material and make a good faith attempt to
        contact the user who uploaded or embedded the material by email.
      </p>

      <p class='p3'>
        <b>Notification of Infringement</b>
      </p>

      <p class='p3'>
        Please provide us with the following information in order to help us take
        appropriate action:
      </p>

      <ul class='ul1 numbered-list'>
        <li class='li3'>
          An electronic or physical signature of a person authorized to act on
          behalf of the copyright owner;
        </li>

        <li class='li3'>
          Identification of the copyrighted work that you claim has been infringed;
        </li>

        <li class='li3'>
          Identification of the material that is claimed to be infringing and
          where it is located on the Service;
        </li>

        <li class='li3'>
          Information reasonably sufficient to permit Koding to contact you,
          such as your address, telephone number, and, email address;
        </li>

        <li class='li3'>
          A statement that you have a good faith belief that use of the material
          in the manner complained of is not authorized by the copyright owner,
          its agent, or law; and
        </li>

        <li class='li3'>
          A statement that the above information is accurate, and that you are
          the copyright owner or are authorized to act on behalf of the owner.
        </li>
      </ul>
      <p class='p3'>
        <b>Counter-Notification</b>
      </p>

      <p class='p3'>
        If you elect to send us a counter notice, to be effective it must be a
        written communication that includes the following (please consult your
        legal counsel or see 17 U.S.C. Section 512(g)(3) to confirm these requirements):
      </p>

      <ul class='ul1 numbered-list'>
        <li class='li3'>
          A physical or electronic signature of the user.
        </li>

        <li class='li3'>
          Identification of the material that has been removed or to which access
          has been disabled and the location at which the material appeared before
          it was removed or access to it was disabled.
        </li>

        <li class='li3'>
          A statement under penalty of perjury that the subscriber has a good
          faith belief that the material was removed or disabled as a result of
          mistake or misidentification of the material to be removed or disabled.
        </li>

        <li class='li3'>
          The user&rsquo;s name, address, and telephone number, and a statement
          that the user consents to the jurisdiction of Federal District Court
          for the judicial district in which the address is located, or if the
          subscriber&rsquo;s address is outside of the United States, for any
          judicial district in which Koding may be found, and that the subscriber
          will accept service of process from the person who provided notification
          under subsection (c)(1)(C) or an agent of such person.
        </li>
      </ul>
      <p class='p3'>
        Please be advised that you may be liable for damages (including costs and
        attorneys&rsquo; fees) if you materially misrepresent that material or
        activity is infringing &ndash; and we have and will seek to collect those
        damages.
      </p>

      <p class='p3'>
        The above requested information must be submitted to Koding at the
        following address, marked &quot;Copyright Notice&quot;:
      </p>

      <p class='p3'>
        Koding, Inc.<br>
        358 Brannan<br>
        San Francisco CA 94107<br>
        USA<br><br>
        or via email at <span class='s1'>legal@koding.com</span>, Subject: DMCA Notice
      </p>

      <p class='p3'>
        Please note that this procedure is exclusively for notifying Koding that
        your copyrighted material has been infringed. It does not constitute
        legal advice. You acknowledge that if you fail to comply with all of the
        requirements of this section, your DMCA notice may not be valid.
      </p>

    </div>
    """


