#! 5b895b3b-d10f-4a16-88ba-0b2126d4475a
# title: ide_create_duplicate_delete_folder_file
# start_uri: /
# tags: automated
#

# create_team_with_existing_user_stack_related is embedded
- 5e284d48-6055-49c0-91ea-c73681036aca

# redirect: false
Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New folder' in the menu
Do you see new folder 'NewFolder' added to the file tree? Is folder name displayed in edit mode?

Enter '{{random.address_state}}{{random.number}}' folder name and press Enter
Do you see folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree?

Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Duplicate' in the menu ( http://snag.gy/a8gQD.jpg )
Do you see a new folder '{{random.address_state}}{{random.number}}_1' created?

Open filetree menu and click 'New file'
Do you see new file 'NewFile.txt' added to the file tree? Is file name displayed in edit mode?

Enter '{{random.address_city}}{{random.number}}.txt' file name and press Enter
Do you see file '{{random.address_city}}{{random.number}}.txt' with green icon in the file tree?

Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Watch file' ( http://snag.gy/R0uxS.jpg )
Do you see new editor tab with file content opened and green message 'This is a file watcher, which allows you to ...' displayed?

Try to enter some text in the editor
Are you unable to enter any text?

Mouse over the editor header where the file '{{random.address_city}}{{random.number}}.txt' is opened and click 'x' icon
Is editor tab closed?

Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Duplicate'
Do you see new file '{{random.address_city}}{{random.number}}_1.txt' displayed in the file tree?

Open menu for the '{{random.address_city}}{{random.number}}_1.txt' file in file tree and click 'Rename'
Is file name displayed in edit mode in the file tree?

Enter '{{random.address_city}}{{random.number}}_renamed.txt' file name and press Enter
Is file name changed to '{{random.address_city}}{{random.number}}_renamed.txt' and file is displayed in the file tree?

Double click any file in the file tree
Do you see a new editor tab opened for this file?

Click '+' icon in the header where new files were opened and click 'New File'
Do you see a new editor tab opened and file name is 'untitled.txt'?

Click down arrow icon at the right of  '{{random.address_city}}{{random.number}}.txt' file in the file tree and click 'Delete' in the menu
Do you see 'Are you sure?' text and red 'Delete' button above the file name?

Click 'Delete' button
Is file deleted?

Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Delete' in the menu
Do you see 'Are you sure?' text and red 'Delete' button above the folder name?

Click 'Delete' button
Is folder deleted?
