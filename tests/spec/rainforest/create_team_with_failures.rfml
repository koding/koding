#! 986368ca-bef2-4ee3-9b97-717d068f6ee3
# title: create_team_with_failures
# start_uri: /
# tags: automated
#

Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'
Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button?

Click on 'NEXT' button
Do you see 'Please type a valid email address.' warning? Do you see 'Please enter a team name.' warning?

Enter "{{ random.email }}" in the 'Email Address' and enter "test" in 'Team Name' fields and click on 'NEXT' button
Do you see 'Your team URL' form with 'Your Team URL' field prefilled?

Delete the prefilled URL and click on 'NEXT' button
Have you seen 'Domain name should be longer than 2 characters!' warning? Do you see the red border around the text field?

Enter 'sandbox' and click on 'NEXT' button
Have you seen 'Invalid domain!' warning? Do you see the red border around the text field?

Enter 'koding' and click on 'NEXT' button
Have you seen 'Domain is taken!' warning? Do you see the red border around the text field?

Enter '{{ random.last_name }}{{ random.number }}' as converted to uppercase and click on 'NEXT' button 
Do you see 'Your account' form with 'Email address' field prefilled?

Leave 'Your Username' and 'Your Password' fields empty and click on 'CREATE YOUR TEAM' button
Do you see 'For username only lowercase letters and numbers are allowed!' and 'Passwords should be at least 8 characters.' warnings? Do you see the red border around the text fields?

Enter 'aaa' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button
Do you see 'Username should be between 4 and 25 characters!' warning? Do you see the red border around the text field for username?

Enter 'koding' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button
Have you seen 'Sorry, "koding" is already taken!' warning?

Enter '{{ random.first_name }}{{ random.number }}' as converted to uppercase in the username field and click on 'CREATE YOUR TEAM' button
Do you see 'Authentication Required' form? If not do you see 'You are almost there,_' title? Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections? Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them?
