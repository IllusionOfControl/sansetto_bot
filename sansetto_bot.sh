#!/bin/bash

set -e


BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IMAGES_UPLOAD_PATH="$BASE_PATH/uploads"
TEMP_PATH="$BASE_PATH/temp"
LAST_ID_FILE="$BASE_PATH/.next"

MAX_IMAGE_SIZE=2500
MAX_THUMBNAIL_SIZE=800

BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID



TELEGRAM_SEND_PHOTO="https://api.telegram.org/bot$BOT_TOKEN/sendPhoto?chat_id=$CHAT_ID"
TELEGRAM_SEND_DOCUMENT="https://api.telegram.org/bot$BOT_TOKEN/sendDocument?chat_id=$CHAT_ID"

if [[ ! -e "$IMAGES_UPLOAD_PATH" ]]; then mkdir "$IMAGES_UPLOAD_PATH"; fi
if [[ ! -e "$TEMP_PATH" ]]; then mkdir "$TEMP_PATH"; fi
if [[ ! -e "$LAST_ID_FILE" ]]; then echo 0 > "$LAST_ID_FILE"; fi


get_random_image() {
  local random_image_path
  local random_image
	random_image_path="$IMAGES_UPLOAD_PATH/$( find "$IMAGES_UPLOAD_PATH" \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \)  | shuf -n 1 )"
	random_image="$( echo "$random_image_path" | rev | cut -d'/' -f 1 | rev )"
	echo "$random_image"
}


get_largest_size() {
	local image="$1"
	local width
	local height
	local largest_size
  width=$(vipsheader -f width "$image")
  height=$(vipsheader -f height "$image")
  largest_size=$((width > height ? width : height))
	echo $largest_size
}


send_photo() {
	local file="$1"
	curl --silent -F photo=@"$file" "$TELEGRAM_SEND_PHOTO" > /dev/null
}


send_document() {
	local file="$1"
	curl --silent -F document=@"$file" "$TELEGRAM_SEND_DOCUMENT" > /dev/null
}


processing_image() {
  local image="$1"
  local largest_size
  largest_size=$(get_largest_size "$IMAGES_UPLOAD_PATH/$image")

  if [[  $largest_size -gt $MAX_IMAGE_SIZE ]]; then
    factor=$(echo "scale=10; $MAX_IMAGE_SIZE / $largest_size" | bc | awk '{printf "%f", $0}' | sed 's/\./,/g')
    vips resize "$IMAGES_UPLOAD_PATH/$image" "$TEMP_PATH/$image" "$factor"
  else
    cp "$IMAGES_UPLOAD_PATH/$image" "$TEMP_PATH/$image"
  fi

  if [[ $largest_size -gt $MAX_THUMBNAIL_SIZE ]]; then
    factor=$(echo "scale=10; $MAX_THUMBNAIL_SIZE / $largest_size" | bc | awk '{printf "%f", $0}' | sed 's/\./,/g')
    vips resize "$IMAGES_UPLOAD_PATH/$image" "$TEMP_PATH/thumb_$image" "$factor"
  else
    cp "$IMAGES_UPLOAD_PATH/$image" "$TEMP_PATH/$image"
  fi
}

main() {
  image="$(get_random_image)"
  echo "$image"
  if [[ -z $image ]]; then
	  echo "Image folder is empty"
  fi

  if [[ -n $image ]]; then
    processing_image "$image"
    send_photo "$TEMP_PATH/thumb_$image"
    send_document "$TEMP_PATH/$image"

    rm "$IMAGES_UPLOAD_PATH/$image"
    rm "$TEMP_PATH/$image"
    rm "$TEMP_PATH/thumb_$image"
  fi
}

main
