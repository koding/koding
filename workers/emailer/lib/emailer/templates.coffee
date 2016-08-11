module.exports = TEMPLATES = (data = {}) ->

  REQUEST_NEW_PASSWORD :
    subject            : 'Your Koding password recovery link.'
    content            : """

    Hi #{data.username or 'there'},

    We received a request to reset your login credentials for Koding.com.
    If you did not request a password reset, you can ignore this email.

    Follow #{data.tokenUrl} to reset your password.

  """

  CHANGED_PASSWORD     :
    subject            : 'Your Koding password was changed.'
    content            : """

    Hi #{data.username or 'there'},

    This is a notification that your password has been successfully
    updated. If you did not request a password change, please contact us
    (support@koding.com) immediately.

  """

  CHANGED_EMAIL        :
    subject            : 'Your Koding email was changed.'
    content            : """

    Hi #{data.username or 'there'},

    This is a notification and confirmation message that your email address
    has been successfully updated. If you did not change your email address
    recently, please contact us (support@koding.com) immediately.

  """

  REQUEST_EMAIL_CHANGE :
    subject            : "#{data.username or 'Hello'}, please confirm your
                          email address."
    content            : """

    Your confirmation PIN code: #{data.pin}

    Please use this PIN code to confirm changes made to your email address.

  """

  INVITED_TEAM         :
    subject            : 'You are invited to join a team on Koding'
    content            : """

    You've been invited to join Koding, by: #{data.inviter}

    Hi #{data.username or 'there'},

    You received this email because #{data.inviter} would like you to join
    #{data.groupName}'s Team on Koding.com

    To accept the invite please follow the link: #{data.link}

    Koding automates server provisioning and gives developers the ability
    to spin up new Virtual Machines in minutes. Koding allows users to:
    collaborate in real time and onboard new developers in minutes;
    all while use the IDEs you already know and love.

    Get started with Koding today!

  """
