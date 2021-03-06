Instructions
---------------

Create a backup of your amp's preset files using *Fender's FUSE* software. (Main Menu > Utilities > Backup)

Launch *Speed Shop*, and open the *FUSE*-created backup folder you would like to edit. By default, the app will open to the default *FUSE* backup folder, however, you may browse to a different location if you like. The default backup folder is located at:

~/Documents/Fender/FUSE/Backups

Drag and drop presets in the table to reorder them, or drag presets into the Quick Access spots. You can also change the description of the backup if you like. When you're done, save the backup file using either the **Save** or **Save as New Backup** command in the File menu. Updated backups will be saved to the FUSE folder location mentioned above. Files saved elsewhere will not be seen by FUSE when trying to transfer them to the amp.

When you're ready to transfer the modified backup to your amp, return to *FUSE* and use the Main Menu > Utilities > Restore... command. Select the new backup, and send it over to your amp.

Remember - this app is designed to manipulate backup files for your Mustang-series amp. As with all software, there is always a possibility something may go wrong. I strongly recommend that you create a backup your original backup files before using this app. The creator of this software assumes no responsibility for damaged or corrupted backup files. Use at your own risk. Really. (Honestly, I'm pretty sure that you'll be just fine, and I've done some pretty thorough testing of this with my own personal gear, and it hasn't caught fire or otherwise stopped working yet. You'll likely have no problems at all.)


**This app is in no way created by, endorsed, or otherwise affiliated with Fender Musical Instruments Corporation.**


Release Notes
-------------

# 0.9
* Initial test release

# 0.9.1
* Added G-Dec support

# 0.9.2
* Added Mustang V.2 support

# 0.9.3
* **New feature:** Copy preset list to clipboard for pasting into other apps
* **Bug Fix:** Multi-selection drag & drop (#2)
* **Bug Fix:** Time format issue when saving new backups (#1)
* **Bug Fix:** Resolving some issues with saving QA presets

# 0.9.4
* **New feature:** Prompt to save modified backups when loading or quitting. (#15)
* **New feature:** Notifying user in UI of modified status
* **Improvement:** Improved drag & drop of multiple rows

# 0.9.5
* **New feature:** Speed shop ahora habla español. Es spricht auch Deutsch. Et un peu de français.
* **New feature:** Put currently loaded backup name into titlebar.
* **Improvement:** Undo/redo support.
* **Improvement:** Misc UI improvements.

# 0.9.6
* **Bug Fix:** Resolves a potential crash when loading backups
* **Bug Fix:** Fixes an issue where backups could be saved incorrectly, preventing them from being opened again.
