# Sansetto - art bot

The bot is represented by a simple script that sends images in telegram to a specific group (sent as an image and a document).

**Directories**:
- "/original" - new images to be processed
- "/images" - images to be sent as documents.
- "/thumbnails" - images to be sent as images.

**How the script works**:
1. Receiving processed images (images are pre-processed to meet telegram requirements)
2. Sending an image and a document.
3. Scan the directory for new images and process them.

**Requirements**:
- Linux
- ImageMagick
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
