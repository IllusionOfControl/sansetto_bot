#!/bin/bash

set -e


BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
IMAGES_UPLOAD_PATH="$BASE_PATH/uploads"
TEMP_PATH="$BASE_PATH/temp"
LOG_FILE_PATH="$BASE_PATH/journal.log"
LAST_ID_FILE_PATH="$BASE_PATH/.last_id"

MAX_IMAGE_SIZE=2500
MAX_THUMBNAIL_SIZE=800

BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID


if [[ ! -e "$IMAGES_UPLOAD_PATH" ]]; then mkdir "$IMAGES_UPLOAD_PATH"; fi
if [[ ! -e "$TEMP_PATH" ]]; then mkdir "$TEMP_PATH"; fi
if [[ ! -e "$LAST_ID_FILE_PATH" ]]; then echo 0 > "$LAST_ID_FILE_PATH"; fi


env_up() {
  if [ -f .env ] then
    export $(cat .env | sed 's/#.*//g' | xargs)
  fi
}

check_env() {
  if [[ -z $BOT_TOKEN && -z $CHAT_ID ]]; then
	  log "Please fill BOT_TOKEN and CHAT_ID in env variables in .env file."
    exit 1
  fi
  if ! command -v vips &> /dev/null; then
	  log "Required libVips but it's not installed. Aborting."; exit 1;
    exit 1
  fi
}


get_current_id() {
	local id=$(< $LAST_ID_FILE_PATH)
  echo $((id + 1)) > "$IMAGES_ORIGINAL_PATH"
  echo id
}


current_timestamp() {
  echo $(date +'%m/%d/%Y %H:%M:%S')
}


log() {
  local text="$1"
  echo "[$(current_timestamp)] $text" | tee $LOG_FILE_PATH
}


get_random_image() {
  local random_image_path
  local random_image
	random_image_path="$IMAGES_UPLOAD_PATH/$(find "$IMAGES_UPLOAD_PATH" \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \)  | shuf -n 1)"
	random_image="$(echo "$random_image_path" | rev | cut -d'/' -f 1 | rev)"
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
  local uri="https://api.telegram.org/bot$BOT_TOKEN/sendPhoto?chat_id=$CHAT_ID"
	curl --silent -F photo=@"$file" "$uri" > /dev/null
}


send_document() {
	local file="$1"
  local uri="https://api.telegram.org/bot$BOT_TOKEN/sendDocument?chat_id=$CHAT_ID"
	curl --silent -F document=@"$file" "$uri" > /dev/null
}


processing_image() {
  local image="$1"
  local largest_size
  largest_size=$(get_largest_size "$IMAGES_UPLOAD_PATH/$image")

  if [[ $largest_size -gt $MAX_IMAGE_SIZE ]]; then
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
  env_up
  check_env

  image="$(get_random_image)"
  if [[ -z $image ]]; then
	  log "Image folder is empty."
  fi

  if [[ -n $image ]]; then
    local new_filename="sansetto_$get_current_id.jpg"
    log "Found image on path $image"
    log "Renaming image to $new_filename"
    
    mv $image $new_filename
    image=$new_filename

    log "Processing and sending the image."

    processing_image "$image"
    send_photo "$TEMP_PATH/thumb_$image"
    send_document "$TEMP_PATH/$image"

    log "Uploaded in Telegram."

    rm "$IMAGES_UPLOAD_PATH/$image"
    rm "$TEMP_PATH/$image"
    rm "$TEMP_PATH/thumb_$image"

    log "Completed."
  fi
}

main
