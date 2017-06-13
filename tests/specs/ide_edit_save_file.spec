#! cb054b5e-447f-43ee-bf5a-451b06b1ed53
# title: ide_edit_save_file
# start_uri: /
# tags: automated
#

# create_team_with_existing_user_stack_related is embedded
- 5e284d48-6055-49c0-91ea-c73681036aca

# redirect: false
Click to arrow next to /home/rainforestqa99 in the middle section and then click to 'New File' in menu displayed
Do you see new file 'NewFile.txt' added to the file tree?

Enter 'file{{random.number}}.txt' file name and press Enter
Do you see file 'file{{random.number}}.txt' with green icon in the file tree?

Double click on the 'file{{random.number}}.txt' file
Do you see a new editor tab opened for this file?

Enter 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' text in the editor
Do you see text you have entered as it is?

Mouse over the editor header where the file 'file{{random.number}}.txt'  is opened and click down arrow icon
Do you see Menu with 'Save', 'Save As...' and other items (like on screenshot http://snag.gy/7yOOm.jpg)?

Click 'Save' in the menu
Did you not see any error?

Make some changes in the editor, Mouse over the editor header where the file 'file{{random.number}}.txt' is opened, click down arrow icon and Click 'Save As...' in the menu
Do you see the form with 'Filename', 'Select a folder' field?

Enter 'newfile{{random.number}}.txt' file name, select '.config' in 'Select a folder' field and click 'SAVE'
Do you see a new editor tab opened for 'newfile{{random.number}}.txt' file?

Click '.config' in file tree list on the left
Do you see the 'newfile{{random.number}}.txt' file under '.config' folder?

Mouse over the editor header where the file 'newfile{{random.number}}.txt' is opened and click 'x' icon
Is editor tab closed?

Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon
Do you see a pop-up with 'Do you want to save your changes?' title?

Click on 'DON'T SAVE' button
Is the editor tab closed?

Double click on the 'file{{random.number}}.txt' file
Do you see a new editor tab opened for this file? Do you see the same file content you entered before for the original file ('Lorem ipsum...')?

Click second row in the editor, type some random text, press Enter and type some random text againg
Is entered text displayed correctly in the editor?

Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon
Do you see 'Do you want to save your changes?' modal displayed? Do you see 'Don't save' and 'Save and Close' buttons?

Click to 'Save and close' button
Is overlay closed? Is editor tab with 'file{{random.number}}.txt' file also closed?

Double click on the 'file{{random.number}}.txt' file in the filetree
Do you see a new editor tab opened for this file? Do you see the same file content you entered before closing?

Make some changes in the editor, mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon and click 'Don't save' button on the modal
Is overlay closed? Is editor tab with 'file{{random.number}}.txt' file also closed?

Double click on the 'file{{random.number}}.txt' file in the filetree
Do you see a new editor tab opened for this file without the changes from previous step?

# Make some changes in the editor and click 'Ctrl+Option+W (Ctrl+Alt+W)' shortcut
# Do you see 'Do you want to save your changes?' modal displayed? Do you see 'Cancel', 'Don't save' and 'Save and close' buttons on the modal?
