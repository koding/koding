#! 1edbcec4-0f80-4a21-a278-951dce8bf458
# title: myaccount
# start_uri: /
# tags: automated
#

# create_team_with_a_new_user is embedded
- 389d1e79-20da-4519-8f85-cb7b73e8ddd4

# redirect: false
Close that modal by clicking (x) from top right corner and click on the team name '{{ random.last_name }}{{ random.number }}' label on top left
Do you see 'Dashboard', 'Support', 'Change Team' and 'Logout'?

Click on 'Dashboard' 
Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side?

Click on 'My Account'
Do you see 'First Name', 'Last Name', 'Email Address' and 'UserName' field?

Enter {{ random.first_name }} in 'First Name' field and enter {{ random.last_name }} in 'Last Name' field then click on 'Save Changes'
Do you see 'Your account information is updated.' message?

Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'
Do you see 'Please verify your current password'  modal?

Enter '11001100' password in current password field then click on 'Confirm'
Do you see 'Current password cannot be confirmed' message?

Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'
Do you see 'Please verify your current password' modal?

Enter current password "{{ random.password }}" in current password field then click on 'Confirm'
Do you see 'Please provide the code that we've emailed' modal?

Enter '0000' in pin code field then click on 'UPDATE E-MAIL'
Do you see 'PIN is not confirmed' message?

# Save image from here: {{ random.image }} to your desktop, click on 'CHANGE AVATAR' and choose the picture by double clicking it
# Do you see the uploaded avatar?

Scroll down then enter new password in 'New Password' field, enter different password in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'
Do you see 'Passwords did not match!' message?

Enter '1234' in 'New Password' field, enter '1234' in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'
Do you see 'Passwords should be at least 8 characters!' message?

Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter invalid current password in 'Your Current Password' field then click 'UPDATE PASSWORD'
Do you see 'Old password did not match our records!' message?

Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter {{ random.password }} in 'Your Current Password' field then click 'UPDATE PASSWORD'
Do you see 'Password successfully changed!' message?

Scroll down to the bottom of the page
Do you see 'Sessions' list?

Click on 'TERMINATE' next to active session
Do you see 'Do you really want to remove this session?' modal?

Click on 'YES'
Are you logged out? Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text in a sign in page?
