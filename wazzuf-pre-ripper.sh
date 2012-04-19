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

	#--------------------------------------------------------
	# Run cropdetect to establish the correct crop rectangle
	#--------------------------------------------------------
	CROP_FRAMES=100
	cropdetect(){
		echo -n "Running Crop Detection... "
		mplayer ${1} -vf cropdetect -nosound -vo null -frames $CROP_FRAMES -sstep 1 -nocache &> /tmp/cropdetect.out
		wait
		crop=$(cat /tmp/cropdetect.out | tr '\r' '\n' | grep 'vf crop\=' | tail -1 | awk -F\= '{print $2}' | awk -F\) '{print $1}')
		echo -ne "\nEstablished crop factor = ${crop}\n"
		rm /tmp/cropdetect.out
	}

case $SOURCE in
BD )
	if [ ! -f $M2TS_FILE ]
	then
		echo -ne "\n *************************************\n"
		echo " M2TS_FILE $M2TS_FILE does not exists ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
	fi

	echo $M2TS_FILE

	echo -ne "\n *************************************\n"
	echo " MPlayer informations"
	echo -ne " *************************************\n"
	mplayer -v -vo null -ao null -frames 0 -identify "$M2TS_FILE" 2>/dev/null | grep -E "^ID_*|^VIDEO*|^AUDIO*|^Selected|^==="
	
	echo -ne "\n *************************************\n"
	echo " FFmpeg informations"
	echo -ne " *************************************\n"
	# This program is not developed anymore and is only provided for compatibility. Use avconv instead (see Changelog for the list of incompatible changes).
	ffmpeg -i $M2TS_FILE -loglevel 0 2>&1| grep -E "Duration|Stream"

	echo -ne "\n *************************************\n"
	echo " Crop detection"
	echo -ne " *************************************\n"
	cropdetect $M2TS_FILE
	;;
DVD )
	check_lsdvd
	echo -ne "\n *************************************\n"
	echo " lsdvd"
	echo -ne " *************************************\n"
	lsdvd -acsv /dev/dvd | grep -v xx

	echo -ne "\n *************************************\n"
	echo " MPlayer"
	echo -ne " *************************************\n"
	mplayer -osdlevel 3 -ss $VIDEO_BEGIN -ao null dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS -vf cropdetect
        ;;
ISO )
	if [ ! -f $ISO_FILE ]
	then
		echo -ne "\n *************************************\n"
		echo " ISO_FILE $ISO_FILE does not exists ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
	fi

	check_lsdvd
	echo -ne "\n *************************************\n"
	echo " lsdvd"
	echo -ne " *************************************\n"
	lsdvd -acsv $ISO_FILE 2>/dev/null | grep -v xx
	
	echo -ne "*************************************\n"
	echo " MPlayer informations"
	echo -ne " *************************************\n"
	mplayer -v -vo null -ao null -frames 0 -identify "$ISO_FILE" 2>/dev/null | grep -E "^ID_*|^VIDEO*|^AUDIO*|^Selected|^==="

	echo -ne "\n *************************************\n"
	echo " FFmpeg informations"
	echo -ne " *************************************\n"
	ffmpeg -i $ISO_FILE -loglevel 0 2>&1 | grep -E "Duration|Stream"

	echo -ne "\n *************************************\n"
	echo " Crop detection: Title $DVD_TITLE_NUMBER"
	echo -ne " *************************************\n"
	cropdetect "-dvd-device $ISO_FILE dvd://$DVD_TITLE_NUMBER"
	;;
* )
        echo -ne "\n Media source problem: make sure you filled DVD ISO BD in configuration file\n"
        exit 1
        ;;
esac

exit 0
