# Sansetto - art bot

The bot is represented by a simple script that sends images in telegram to a specific group (sent as an image and a document).

For the script to work, add it to cron and put the images in /uploads. 
After sending, the original images will be deleted.

**Requirements**:
- Linux
- libVips
- Cron

**Installation**:

In the terminal, enter
```bash
$ crontab -e
```
Where then
```
15 0 0 0 0 [script path]
```
