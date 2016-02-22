HANDLERS =
  installKd    : 'installKd'
  buildStack   : 'buildStack'
  messageAdmin : 'messageAdmin'
  skip         : 'skip'
  readMe       : 'readMe'

boxes =

  configureStack :
    """
    <h3>Configure Stack</h3>
    <p>
      Create simple, shareable stack script that serves as a
      blueprint for your team’s entire infrastructure.
    </p>
    <ul>
      <li>Koding uses your cloud provider</li>
      <li>Requires cloud provider credentials (e.g. AWS access key ID & secret access key).</li>
    </ul>
    <div class="button-bar">
      <a href='#' data-handler='#{HANDLERS.skip}'>Skip this</a>
      <a href='/Stacks/Group-Stack-Templates/welcome' testpath="configure-stack-button" class="button">START</a>
    </div>
    """

  pendingStack :
    """
    <h3>Stack Pending</h3>
    <p>
      <strong>Requirements not met.</strong>
      No VMs have been allocated. Your
      team administrator needs to create
      a stack. Please ping them to
      help get things moving.
    </p>
    <p>
      Or you can <a href='/Stacks/My-Stack-Templates/new'>create your personal stack</a> to see how things work.
    </p>
    <div class="button-bar">
      <a href='#' data-handler='#{HANDLERS.skip}'>Skip this</a>
    </div>
    """

  buildStack :
    """
    <h3>Build Stack</h3>
    <p>
      <strong>Your stack is ready!</strong>
      To view your VMs that your admin has assigned to you,
      you need to go to your IDE and build your stack.
    </p>
    <div class="button-bar">
      <a href='#' data-handler='#{HANDLERS.skip}'>Skip This</a>
      <a href='/IDE' class="button">START</a>
    </div>
    """

  completeStack :
    """
    <h3><figure></figure>Complete</h3>
    <p>
      <strong>Your stack is configured!</strong>
      To view your VMs that your admin has assigned to you,
      you need to build your stack.
    </p>
    <div class="button-bar">
      <a href='/IDE' data-handler='#{HANDLERS.readMe}'>Build Stack</a>
      <a href='#' class="button" data-handler='#{HANDLERS.skip}'>NEXT</a>
    </div>
    """

  inviteTeam:
    """
    <h3>Invite Team</h3>
    <p>Get your teammates working together.</p>
    <ul>
      <li>Get help configuring your stack</li>
      <li>Collaborate in real-time with chat, video, and more.</li>
    </ul>
    <p class="slack">
      You can also invite using <a href='/Admin/Invitations/Slack' class="slack-logo"></a>
    </p>
    <div class="button-bar">
      <a href='#' data-handler='#{HANDLERS.skip}'>Skip this</a>
      <a href='/Admin/Invitations/Invite' class="button">START</a>
    </div>
    """

  installKd:
    """
    <h3>Install kd</h3>
    <p>
      <strong>For use with local IDE.</strong>
      A command line program that allows you
      to use local IDEs with your VMs.
    </p>
    <ul>
      <li><cite class='code'>sudo</cite> Permissions required</li>
      <li>Works for OSX and Linux</li>
      <li><cite class='code'>kd</cite> is currently in Beta</li>
    </ul>
    <div class="button-bar">
      <a href='#' data-handler='#{HANDLERS.skip}'>Skip this</a>
      <a href='#' class="button" data-handler='#{HANDLERS.installKd}'>GET CODE</a>
    </div>
    <div class='copy-tooltip install-kd-command hidden'>
      <i>Copied to clipboard</i>
      <div><cite></cite><span>curl -sL https://kodi.ng/d/kd | bash -s efc225c9</span></div>
    </div>
    """

module.exports = { boxes, HANDLERS }