#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob
shopt -s nocaseglob

# test for ffmpeg in the path
if ! hash "ffmpeg" >/dev/null 2>&1; then
  echo "Error: ffmpeg not found in path"
  exit 1
fi

# test for jpeginfo binary
if ! hash "jpeginfo" >/dev/null 2>&1; then
  echo "Error: missing jpeginfo command"
  exit 1
fi

# Define global variables and set defaults
INPUT_PATH="$PWD"
OUTPUT_PATH="$PWD/encoded.mp4"
ENCODE_ARCHIVE=1
ENCODE_ARCHIVE_HARDWARE=1
HD_ARCHIVE=1
JPEG_EXT="none"
BADPEG=1
TWITTER=1

# print out usage
usage() {
  cat <<EOF
USAGE: ./encode -p /Volumes/fast/timelapseSource -o /Volumes/fast/timelapseArchive.mp4
OPTIONS:
   -p    Path to source images
   -b    Search for bad jpeg files and delete them without warning
   -o    Path to output file including extension
   -a    Encode with archive format
   -v    Encode with hevc hardware encoder 60fps
   -d    Encode with HD 1080p 60fps
   -t    Encode for twitter
   -h    Help
EOF
  exit
}

# process options and arguments
while getopts "bp:o:adtvh" OPTION; do
  case $OPTION in
  h) usage && exit 1 ;;
  p) INPUT_PATH=$OPTARG ;;
  o) OUTPUT_PATH=$OPTARG ;;
  a) ENCODE_ARCHIVE=0 ;;
  v) ENCODE_ARCHIVE_HARDWARE=0 ;;
  d) HD_ARCHIVE=0 ;;
  t) TWITTER=0 ;;
  b) BADPEG=0 ;;
  esac
done

# check input type
if [[ -d ${INPUT_PATH} ]]; then
  echo "${INPUT_PATH} is a directory"
  INPUT_PATH_TYPE=dir
elif [[ -f "${INPUT_PATH}" ]]; then
  echo "${INPUT_PATH} is a file"
  INPUT_PATH_TYPE=file
else
  echo "${INPUT_PATH} is not valid"
  exit 1
fi

## get the first jpg file in the provided path and get details on it
get_info() {
  FIRST_JPG=$(find ${INPUT_PATH} -maxdepth 1 -name '*.JPG' -o -name '*.jpg' -o -name '*.mp4' -o -name '*.MP4' -o -name '*.mkv' -o -name '*.MKV' | head -n 1) || true
  if [[ -f "$FIRST_JPG" ]]; then
    jpeginfo -i "$FIRST_JPG"
    JPEG_EXT=$(rev <<<"$FIRST_JPG" | cut -d '.' -f 1 | rev)
  else
    echo "Error: ${INPUT_PATH}/*.$JPEG_EXT not found!"
    exit 1
  fi
}

#exit 0

badpeg() {
  # test for jpeginfo binary
  if ! (command -v jpeginfo >/dev/null 2>&1); then
    echo "missing jpeginfo command"
    exit 1
  fi
  echo "Deleting any invalid jpeg files found..."
  # delete bad jpeg files
  find ${INPUT_PATH} -maxdepth 1 -name '*.JPG' -o -name '*.jpg' | xargs jpeginfo -c -q -d - >/dev/null 2>&1 || true
}

archive_encode() {
  if [[ ${INPUT_PATH_TYPE} == 'dir' ]]; then
    get_info
    ffmpeg -y -r 60 -thread_queue_size 8192 -pattern_type glob -i "${INPUT_PATH}/*.$JPEG_EXT" -vcodec libx264 -crf 26 -tune fastdecode -preset slow -c:v libx265 -pix_fmt yuv420p -tag:v hvc1 ${OUTPUT_PATH}
  else
    echo "archive encode only works with source dir"
  fi
}

archive_hardware_encode() {
  if [[ ${INPUT_PATH_TYPE} == 'dir' ]]; then
    get_info
    ffmpeg -y -r 60 -pattern_type glob -i "${INPUT_PATH}/*.$JPEG_EXT" -r 60 -vcodec hevc_videotoolbox -b:v 6000k -tag:v hvc1 -c:a eac3 -b:a 224k ${OUTPUT_PATH}
  else
    echo "archive encode only works with source dir"
  fi
}

hd_encode() {
  if [[ ${INPUT_PATH_TYPE} == 'dir' ]]; then
    get_info
    ffmpeg -y -r 30 -thread_queue_size 8192 -pattern_type glob -i "${INPUT_PATH}/*.$JPEG_EXT" -vcodec libx264 -crf 22 -tune fastdecode -vf "scale=iw*min(1920/iw\,1080/ih):ih*min(1920/iw\,1080/ih), pad=1920:1080:(1920-iw*min(1920/iw\,1080/ih))/2:(1080-ih*min(1920/iw\,1080/ih))/2" -preset fast -c:v libx265 -pix_fmt yuv420p -tag:v hvc1 ${OUTPUT_PATH}
  elif [[ ${INPUT_PATH_TYPE} == 'file' ]]; then
    ffmpeg -y -r 30 -thread_queue_size 8192 -i "${INPUT_PATH}" -vcodec libx264 -crf 22 -tune fastdecode -vf "scale=iw*min(1920/iw\,1080/ih):ih*min(1920/iw\,1080/ih), pad=1920:1080:(1920-iw*min(1920/iw\,1080/ih))/2:(1080-ih*min(1920/iw\,1080/ih))/2" -preset fast -c:v libx265 -pix_fmt yuv420p -tag:v hvc1 ${OUTPUT_PATH}
  fi
}

twitter_encode() {
  if [[ ${INPUT_PATH_TYPE} == 'dir' ]]; then
    get_info
    ffmpeg -y -framerate 30 -pattern_type glob -i "${INPUT_PATH}/*.$JPEG_EXT" -pix_fmt yuv420p -vf "scale=iw*min(1280/iw\,720/ih):ih*min(1280/iw\,720/ih), pad=1280:720:(1280-iw*min(1280/iw\,720/ih))/2:(720-ih*min(1280/iw\,720/ih))/2" -b:v 5120k -bufsize 1M ${OUTPUT_PATH}
  elif [[ ${INPUT_PATH_TYPE} == 'file' ]]; then
    ffmpeg -y -r 30 -i "${INPUT_PATH}" -pix_fmt yuv420p -vf "scale=iw*min(1280/iw\,720/ih):ih*min(1280/iw\,720/ih), pad=1280:720:(1280-iw*min(1280/iw\,720/ih))/2:(720-ih*min(1280/iw\,720/ih))/2" -b:v 5120k -bufsize 1M ${OUTPUT_PATH}
  fi
}

if [[ $BADPEG == 0 ]]; then
  badpeg
fi

if [[ $ENCODE_ARCHIVE == 0 ]]; then
  archive_encode
  open ${OUTPUT_PATH}
fi

if [[ $ENCODE_ARCHIVE_HARDWARE == 0 ]]; then
  archive_hardware_encode
  open ${OUTPUT_PATH}
fi

if [[ $HD_ARCHIVE == 0 ]]; then
  hd_encode
  open ${OUTPUT_PATH}
fi

if [[ $TWITTER == 0 ]]; then
  twitter_encode
  echo "twitter encoded"
  open ${OUTPUT_PATH}
fi

# test for jpegs at the provided path
echo FIN
exit 0
