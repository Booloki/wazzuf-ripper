#! /bin/bash
# Wazzuf Ripper
# DVD/BD pre-rip script helping to fill configuration file
# booloki@gmail.com

CONF_FILE="wazzuf-ripper.conf"
FUNCTIONS_PATH="wazzuf-ripper-functions"
FUNCTIONS_CHECK="$FUNCTIONS_PATH/wazzuf-functions-check"
WAZZUF_FILES=$CONF_FILE

# check wazzuf files
source $FUNCTIONS_CHECK
checkandsource_wazzuf_files

check_mplayer
check_ffmpeg
check_avconv

ISO_FILE_PATH=$SOURCE_DIRECTORY/$ISO_FILE
M2TS_FILE_PATH=$SOURCE_DIRECTORY/$ISO_FILE

## pre-rip functions

# Run cropdetect to establish the correct crop rectangle
CROP_FRAMES=100
cropdetect(){
	echo -n "Running Crop Detection... "
	if [[ "$ISO_FILE_PATH" =~ \ |\' ]]
	then
		echo -ne "\n *************************************\n"
		echo " Warning: Path/filename to iso file $ISO_FILE_PATH must not contain spaces for croptetection.."
		echo -ne " *************************************\n"
	else
		mplayer ${1} -vf cropdetect -nosound -vo null -frames $CROP_FRAMES -sstep 1 -nocache &> /tmp/cropdetect.out
		wait
		crop=$(cat /tmp/cropdetect.out | tr '\r' '\n' | grep 'vf crop\=' | tail -1 | awk -F\= '{print $2}' | awk -F\) '{print $1}')
		echo -ne "\nVIDEO_CROP=\"${crop}\"\n"
		rm /tmp/cropdetect.out
	fi
}

	## 'decode' avconv output file
avconv-decode(){
	while read line
	do
		ID_HEX=`echo ${line} | grep '^Stream' | cut -d '[' -f 2 | cut -d ']' -f 1`
		if [[ ! $ID_HEX == "" ]]; then
			echo "ID $(($ID_HEX)) - `echo ${line} | grep ^Stream | cut -d ' ' -f 3-`"
		fi
	done  < ${1}
}

	## 'decode' lsdvd output file
lsdvd-decode(){
	while read line
	do
		ID_HEX=`echo ${line} | grep -vE '^Title|VTS' | grep -o '.\{5\}$' | sed s/,//`
		if [[ ! $ID_HEX == "" ]]; then
			echo "ID $(($ID_HEX)) - `echo ${line} | sed s/', Stream id: ....'//`"
		fi
	done  < ${1}
}

## enter source directory
cd $SOURCE_DIRECTORY

## pre-rip source choice

case $SOURCE in
BD )
	if [ ! -f "$M2TS_FILE_PATH" ]
	then
		echo -ne "\n *************************************\n"
		echo " M2TS_FILE_PATH $M2TS_FILE_PATH does not exists ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
	fi

	echo -ne " *************************************\n"
	echo " MPlayer informations"
	mplayer -v -vo null -ao null -frames 0 -identify "$M2TS_FILE_PATH" 2>/dev/null > M2TS-mplayer.info
	echo "-> see M2TS-mplayer.info"

	echo -ne " *************************************\n"
	echo " avconv informations"
	avconv -i "$M2TS_FILE_PATH" 2> M2TS-avconv.info
	echo "-> see M2TS-avconv.info"

	echo -ne " *************************************\n"
	echo M2TS_FILE_PATH=\"$M2TS_FILE_PATH\"
	cropdetect $M2TS_FILE_PATH

	echo -ne "*************************************\n"
	echo "All tracks:"
	avconv-decode M2TS-avconv.info
	;;
DVD )
	check_lsdvd

	echo -ne "*************************************\n"
	echo " lsdvd"
 	lsdvd -acsv /dev/dvd 2>/dev/null > DVD-lsdvd.info
	echo "-> see DVD-lsdvd.info"

	echo -ne "*************************************\n"
	echo " MPlayer"
	mplayer -v -vo null -ao null -frames 0 -identify /dev/dvd 2>/dev/null > DVD-mplayer.info
	echo "-> see DVD-player.info"

	echo -ne "*************************************\n"
	grep "^Disc Title" DVD-lsdvd.info
	DVD_TITLE_NUMBER=`grep "^Longest track:" DVD-lsdvd.info | sed s/'Longest track: '//`
	echo "Longest track chosen for crop detection: Title $DVD_TITLE_NUMBER"
	echo `grep "Title: $DVD_TITLE_NUMBER" DVD-lsdvd.info | cut -d "," -f 2`
	cropdetect "dvd://$DVD_TITLE_NUMBER"
	lsdvd -t $DVD_TITLE_NUMBER -acsv /dev/dvd 2>/dev/null | grep -E "Subtitle|Audio|VTS" > DVD-lsdvd-T$DVD_TITLE_NUMBER.info
	grep VTS DVD-lsdvd-T$DVD_TITLE_NUMBER.info

	echo -ne "*************************************\n"
	echo "Audio/Subtitles tracks (Title $DVD_TITLE_NUMBER):"
	lsdvd-decode DVD-lsdvd-T$DVD_TITLE_NUMBER.info

	# copy DVD to iso file ?
	DVD_MOUNT_PATH=`mount | grep udf | cut -d ' ' -f 3`
	DVD_MOUNT_NAME=`echo $DVD_MOUNT_PATH | cut -d '/' -f 3`
	echo -ne "*************************************\n"
	echo -ne " Wanna copy $DVD_MOUNT_PATH to $SOURCE_DIRECTORY/$ISO_FILE file ? (N/y)\n"
	read answer
	case $answer in
	y* | Y* )
		vobcopy -m -i $DVD_MOUNT_PATH -o $SOURCE_DIRECTORY
		cd $SOURCE_DIRECTORY
		mkisofs -allow-limited-size -dvd-video -o $ISO_FILE $DVD_MOUNT_NAME
		rm -rf $DVD_MOUNT_NAME
		;;
	esac
	;;
ISO )
	if [ ! -f "$ISO_FILE_PATH" ]
	then
		echo -ne "\n *************************************\n"
		echo " ISO_FILE_PATH $ISO_FILE_PATH does not exists ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
	fi

	check_lsdvd
	echo -ne "*************************************\n"
	echo " lsdvd"
	lsdvd -acsv "$ISO_FILE_PATH" 2>/dev/null > ISO-lsdvd.info
	echo "-> see ISO-lsdvd.info"
	
	echo -ne "*************************************\n"
	echo " MPlayer informations"
	mplayer -v -vo null -ao null -frames 0 -identify "$ISO_FILE_PATH" 2>/dev/null > ISO-mplayer.info
	echo "-> see ISO-lsdvd.info"

	echo -ne "*************************************\n"
	echo " avconv informations"
	avconv -i "$ISO_FILE_PATH" 2> ISO-avconv.info
	echo "-> see ISO-avconv.info"

	check_7z
	echo -ne "*************************************\n"
	echo " DVD structure informations"
	7z l "$ISO_FILE_PATH" > ISO-DVDstruct.info
	echo "-> see ISO-DVDstruct.info"

	echo -ne "*************************************\n"
	echo ISO_FILE_PATH=\"$ISO_FILE_PATH\"
	grep "^Disc Title" ISO-lsdvd.info
	DVD_TITLE_NUMBER=`grep "^Longest track:" ISO-lsdvd.info | sed s/'Longest track: '//`
	echo "Longest track chosen for crop detection: Title $DVD_TITLE_NUMBER"
	echo `grep "Title: $DVD_TITLE_NUMBER" ISO-lsdvd.info | cut -d "," -f 2`
	cropdetect "-dvd-device $ISO_FILE_PATH dvd://$DVD_TITLE_NUMBER"

	echo -ne "*************************************\n"
	echo "Audio/Subtitles tracks:"
	avconv-decode ISO-avconv.info
	;;
* )
        echo -ne "\n Media source problem: make sure you filled DVD ISO BD in configuration file\n"
        exit 1
        ;;
esac

exit 0