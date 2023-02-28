#!/bin/bash

cat << EndOfMessage
 __  __ _____ ____    _    ____  ____  _     ___ _____ 
|  \/  | ____/ ___|  / \  / ___||  _ \| |   |_ _|_   _|
| |\/| |  _|| |  _  / _ \ \___ \| |_) | |    | |  | |  
| |  | | |__| |_| |/ ___ \ ___) |  __/| |___ | |  | |  
|_|  |_|_____\____/_/   \_\____/|_|   |_____|___| |_|  
tonikelope Solutions S. L.

EndOfMessage

bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
	# Thanks to -> https://www.baeldung.com/linux/command-line-progress-bar
    terminal_width=$(tput cols)
    bar_size=$((terminal_width-21))
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\033[2K\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e "\nDONE"
    fi
} 

REMOVE_ATER_SPLIT=false

while getopts b:r flag; do
  case "$flag" in
    b) BYTES=$OPTARG;;
    r) REMOVE_ATER_SPLIT=true;;
    \?) echo -e "Usage: $(basename $0) -b BYTES [-r] FILE [OUTPUT_DIR]\n-r Remove original file after split"
		exit 1
	;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$BYTES" ]; then
	echo -e "Usage: $(basename $0) -b BYTES [-r] FILE [OUTPUT_DIR]n-r Remove original file after split"
	exit 1
fi

FILE=${1}

if [ ! -f "$FILE" ]; then
    echo -e "Usage: $(basename $0) -b BYTES [-r] FILE [OUTPUT_DIR]\n-r Remove original file after split"
    exit 1
fi

if [ -d "$2" ]; then

	OUTPUT_DIR="${2}/"
	echo -e "USING OUTPUT DIR -> ${OUTPUT_DIR}\n"

fi

echo -e "SPLIT MAX SIZE (BYTES) -> ${BYTES}\n"

if [ "$REMOVE_ATER_SPLIT" = true ]; then

	echo -e "\n**** WARNING: ${FILE} WILL BE DELETED AFTER SPLIT! ****\n"

fi

date

echo -e "\nGenerating (background) SHA1SUM..."

(sha1sum "$FILE" | awk '{print $1}' > "${OUTPUT_DIR}${FILE}".sha1) &

echo -e "\nSplitting file..."

TOT_SIZE=$(stat -c "%s" "$FILE")

(split --verbose -b "$BYTES" -d --additional-suffix="___" "$FILE" "${OUTPUT_DIR}x" > /dev/null) &

SIZE=0

while [ "$SIZE" -lt "$TOT_SIZE" ]
do
	SIZE=0

	if [ -z "$OUTPUT_DIR" ]; then
		TROZOS=$(ls | grep -Eo 'x[0-9]+___')
	else
		TROZOS=$(ls "$OUTPUT_DIR" | grep -Eo 'x[0-9]+___')
	fi

	for f in $TROZOS
	do
		chunk_size=$(stat -c "%s" "${OUTPUT_DIR}${f}")
		SIZE=$((SIZE+chunk_size))
	done

	show_progress $SIZE $TOT_SIZE

	sleep 1
done

SHA1_FILE_SIZE=$(stat -c "%s" "${OUTPUT_DIR}${FILE}.sha1")

while [ "$SHA1_FILE_SIZE" -eq "0" ]
do
	echo -e "\nWaiting SHA1SUM finish..."
	sleep 1
done

echo -ne "\nRenaming chunks..."

if [ -z "$OUTPUT_DIR" ]; then
	TOTAL=$(ls | grep -Eo 'x[0-9]+___' | wc -l)
	TROZOS=$(ls | grep -Eo 'x[0-9]+___')
else
	TOTAL=$(ls "$OUTPUT_DIR" | grep -Eo 'x[0-9]+___' | wc -l)
	TROZOS=$(ls "$OUTPUT_DIR" | grep -Eo 'x[0-9]+___')
fi

SPLIT_DIRECTORY="${OUTPUT_DIR}${FILE}_SPLIT/"

mkdir "$SPLIT_DIRECTORY"

mv "${OUTPUT_DIR}${FILE}.sha1" "${SPLIT_DIRECTORY}${FILE}.sha1"

i=1

for f in $TROZOS
do
	mv "${OUTPUT_DIR}${f}" "${SPLIT_DIRECTORY}${FILE}.part${i}-${TOTAL}"
	i=$((i+1)) 
done

echo -e "\tOK\n"

if [ "$REMOVE_ATER_SPLIT" = true ]; then

	echo -e "DELETING ${FILE}..."
	rm "$FILE"

fi

date
