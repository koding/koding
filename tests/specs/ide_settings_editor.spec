#! 04b2f960-9f9d-4f9b-8cff-ce4068748c90
# title: ide_settings_editor
# start_uri: /
# tags: automated
#

# create_team_with_existing_user_stack_related is embedded
- 5e284d48-6055-49c0-91ea-c73681036aca

# redirect: false
Open filetree menu by clicking into down arrow next to /home/rainforestqa99 then click 'New file' and then type '{{random.address_city}}{{random.number}}.html' file name (remove .txt extension) and press ENTER
Do you see a new file named '{{random.address_city}}{{random.number}}.html' added to the file tree?

Double click '{{random.address_city}}{{random.number}}.html' file in the file tree
Do you see a new editor tab opened for this file?

Click settings icon at the top of the file tree
Do you see 'Editor Settings' and 'Terminal Settings' instead of file tree?

Toggle 'Trim trailing whitespaces' option on in Editor Settings
Is 'Trim trailing whitespaces' toggle green?

Insert tabs by pressing tab on keyboard, type some spaces and press Enter. Move mouse over to the editor tab where the file '{{random.address_city}}{{random.number}}.html' above of editor pane and click arrow icon and then click to 'Save' action in menu displayed
Are all spaces and tabs removed from the line you entered?

Toggle 'Trim trailing whitespaces' option off in Editor Settings
Is 'Trim trailing whitespaces' toggle gray?

Disable 'Enable Autocomplete' toggle in the 'Editor Settings'
Is 'Enable Autocomplete' toggle gray?

Click editor area, create a new line and type 'tested test' (type, not copy/paste)
Do you see the text entered without any hints at the bottom (hint like this http://snag.gy/HdTHS.jpg shouldn't be displayed)?

Enable 'Enable Autocomplete' toggle in the 'Editor Settings'
Is 'Enable Autocomplete' toggle green?

Click editor area, create a new line and type 'test' (type, not copy/paste)
Do you see the text entered with a hint at the bottom of the text containing words with 'test' in it (like on screenshot http://snag.gy/LnDQx.jpg )?

Toggle 'Enable emmet' on in Editor Settings. Delete all the text in the editor. Type 'html:5' and then press TAB key
Does 'html:5' replaced with '<h5 id="" ></h5>'?

Toggle 'Enable snippets' on
Did it turn to green?

Toggle 'Enable brace, tag completion' off,  clear file content and type '<html>' (type, not copy/paste)
Is tag not completed?

Toggle 'Enable brace, tag completion' on,  clear file content and type '<html>' (type, not copy/paste)
Is tag completed with </html>?

Select 'Vim' for 'Key binding' option in Editor Settings
Do you see red cursor?

Select 'Emacs' for 'Key binding' option in Editor Settings
Do you see green cursor?

Select 'Default' for 'Key binding' option in Editor Settings
Do you see default cursor?

Change 'Font size' option in Editor Settings (try different settings and return to the 12px as result)
Is font size in the editor changed according to selected value?

Change 'Theme' option in Editor Settings
Is color theme for editor changed?

Change value for 'Tab size' option, create a new line in the editor, create tabulation by pressing tab on keyboard and type 'new line'
Is tabulation displayed the number of spaces equals the selected value in the settings?