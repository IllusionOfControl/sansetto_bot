#!/bin/bash

set -e

BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMAGES_ORIGINAL_PATH="$BASE_PATH/original"
IMAGES_PROCESSED_PATH="$BASE_PATH/images"
THUMBNAILS_PATH="$BASE_PATH/thumbnails"

MAX_IMAGE_RESOLUTION=$((2500*2500))
MAX_THUMBNAIL_RESOLUTION=$((800*800))

BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID

TELEGRAM_SEND_PHOTO="https://api.telegram.org/bot$BOT_TOKEN/sendPhoto?chat_id=$CHAT_ID"
TELEGRAM_SEND_DOCUMENT="https://api.telegram.org/bot$BOT_TOKEN/sendDocument?chat_id=$CHAT_ID"

if [[ ! -e "BASE_PATH" ]]; then mkdir "BASE_PATH"; fi
if [[ ! -e "IMAGES_PROCESSED_PATH" ]]; then mkdir "IMAGES_PROCESSED_PATH"; fi
if [[ ! -e "IMAGES_ORIGINAL_PATH" ]]; then mkdir "IMAGES_ORIGINAL_PATH"; fi

get_random_image() {
  local full_path
  local image
	full_path="$IMAGES_PROCESSED_PATH/$( ls $IMAGES_PROCESSED_PATH | shuf -n 1 )"
	image="$( echo "$full_path" | rev | cut -d'/' -f 1 | rev )"
	echo "$image"
}


calculate_resolution() {
	local image="$1"
	local size_h
	local size_w
	size_h=$(identify -format "%h" "$image")
	size_w=$(identify -format "%w" "$image")
	pixel_count=$((size_h * size_w))
	echo $pixel_count
}


send_photo() {
	local file="$1"
	curl --silent -F photo=@"$file" "$TELEGRAM_SEND_PHOTO" > /dev/null
}


send_document() {
	local file="$1"
	curl --silent -F document=@"$file" "$TELEGRAM_SEND_DOCUMENT" > /dev/null
}

processing_images() {
  for image in "$IMAGES_ORIGINAL_PATH"/*; do
    if [[ $image == "$IMAGES_ORIGINAL_PATH/*" ]]; then
      echo "None new images"
      break
    fi

    image="$(echo "$image" | rev | cut -d'/' -f 1 | rev)"

    cp "$IMAGES_ORIGINAL_PATH/$image" "$IMAGES_PROCESSED_PATH"
    cp "$IMAGES_ORIGINAL_PATH/$image" "$THUMBNAILS_PATH"

    image_resolution=$(calculate_resolution "$IMAGES_ORIGINAL_PATH/$image")

    if [[ $image_resolution -gt $MAX_IMAGE_RESOLUTION ]]; then
      convert "$IMAGES_PROCESSED_PATH/$image" -resize $MAX_IMAGE_RESOLUTION@ "$IMAGES_PROCESSED_PATH/$image"
    fi

    if [[ $image_resolution -gt $MAX_THUMBNAIL_RESOLUTION ]]; then
      convert "$THUMBNAILS_PATH/$image" -resize $MAX_THUMBNAIL_RESOLUTION@ "$THUMBNAILS_PATH/$image"
    fi

    rm "$IMAGES_ORIGINAL_PATH/$image"
  done
}

main() {
  image="$(get_random_image)"
  echo "$image"
  if [[ -z $image ]]; then
	  echo "Image folder is empty"
  fi

  if [[ -n $image ]]; then
    send_photo "$THUMBNAILS_PATH/$image"
    send_document "$IMAGES_PROCESSED_PATH/$image"

    rm "$IMAGES_PROCESSED_PATH/$image"
    rm "$THUMBNAILS_PATH/$image"
  fi

  processing_images
}

main
