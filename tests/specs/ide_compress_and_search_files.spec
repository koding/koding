#! acdea8d7-8ef5-434a-850b-fc0cda42a2c0
# title: ide_compress_and_search_files.rfml
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

Open filetree menu and click 'New file'
Do you see new file 'NewFile.txt' added to the file tree? Is file name displayed in edit mode?

Enter '{{random.address_city}}{{random.number}}.txt' file name and press Enter
Do you see file '{{random.address_city}}{{random.number}}.txt' with green icon in the file tree?

Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu
Do you see 'zip command not found' modal window ( http://snag.gy/HnDfH.jpg )?

Click 'Install package' button
Do you see a terminal window with commands performing?

Wait when the process is finished, click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu
Do you see a new file '{{random.address_city}}{{random.number}}.txt.zip' in the file tree?

Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .zip' in the menu
Do you see a new file '{{random.address_state}}{{random.number}}.zip' in the file tree?

Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu
Do you see a new file '{{random.address_city}}{{random.number}}.txt.tar.gz' in the file tree?

Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu
Do you see a new file '{{random.address_state}}{{random.number}}.tar.gz' in the file tree?

Double click '.profile' file in the file tree
Do you see new editor tab opened with this file content?

Click on down arrow on the rigth-side of '.profile' tab that you just opened and select 'Search in All Files'
Do you see a pop-up with 'Find', 'Where', 'Case Sensitive', 'Whole Word', 'Use regexp' texts?

Type 'if' in 'Find' field, check all of the three checkboxes next to 'Case Sensitive', 'Whole Word' and 'Use regexp' fields and click on 'SEARCH'
Is search result opened in a new tab? Is search term 'if' highlighted?

Click on one of the highlighted search term
Is a file opened on a new tab?

