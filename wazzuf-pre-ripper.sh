#! /bin/bash
# Wazzuf Ripper
# DVD/BD pre-rip script helping to fill configuration file
# booloki@gmail.com

CONF_FILE="wazzuf-ripper.conf"
EXTERNAL_TOOLS_PATH="wazzuf-external-tools"
FUNCTIONS_PATH="wazzuf-ripper-functions"
FUNCTIONS_CHECK="$FUNCTIONS_PATH/wazzuf-functions-check"
FUNCTIONS_PRE="$FUNCTIONS_PATH/wazzuf-functions-pre"
FUNCTIONS_IMDB="$FUNCTIONS_PATH/wazzuf-functions-imdb"
WAZZUF_FILES="$CONF_FILE $FUNCTIONS_PRE $FUNCTIONS_IMDB"

# check wazzuf files
source $FUNCTIONS_CHECK
checkandsource_wazzuf_files

check_mplayer
check_avconv

ISO_FILE_PATH=$SOURCE_DIRECTORY/$ISO_FILE
M2TS_FILE_PATH=$SOURCE_DIRECTORY/$M2TS_FILE

# enter source directory
mkdir -p $SOURCE_DIRECTORY
cd $SOURCE_DIRECTORY

# pre-rip source choice
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
	DVD_PATH="/dev/dvd"
	check_lsdvd
	echo -ne "*************************************\n"
	echo " lsdvd informations"
 	lsdvd -acsv $DVD_PATH 2>/dev/null > DVD-lsdvd.info
	echo "-> see DVD-lsdvd.info"

	echo -ne "*************************************\n"
	echo " MPlayer informations"
	mplayer -v -vo null -ao null -frames 0 -identify $DVD_PATH 2>/dev/null > DVD-mplayer.info
	echo "-> see DVD-player.info"

	check_7z
	echo -ne "*************************************\n"
	echo " DVD structure informations"
	7z l $DVD_PATH > DVD-DVDstruct.info
	echo "-> see ISO-DVDstruct.info"

	echo -ne "*************************************\n"
	grep "^Disc Title" DVD-lsdvd.info
	DVD_TITLE_NUMBER=`grep "^Longest track:" DVD-lsdvd.info | sed s/'Longest track: '//`
	if  [[ $VIDEO_TYPE == "SHOW" && $DVD_EPISODES_ORG == "TITLES" ]]; then
		for DVD_TITLE_NUMBER in $DVD_TITLE_LIST
		do
			echo "######### Title: $DVD_TITLE_NUMBER #########"
			lsdvd -t $DVD_TITLE_NUMBER -acsv $DVD_PATH 2>/dev/null | grep -E "Subtitle|Audio|VTS" > DVD-lsdvd-T$DVD_TITLE_NUMBER.info
			echo `grep "Title: " DVD-lsdvd-T$DVD_TITLE_NUMBER.info | cut -d "," -f 2`
			cropdetect "dvd://$DVD_TITLE_NUMBER"
			grep VTS DVD-lsdvd-T$DVD_TITLE_NUMBER.info
			lsdvd-decode DVD-lsdvd-T$DVD_TITLE_NUMBER.info
		done
	else
		echo "Longest track chosen for crop detection: Title $DVD_TITLE_NUMBER"
		echo `grep "Title: $DVD_TITLE_NUMBER" DVD-lsdvd.info | cut -d "," -f 2`
		cropdetect "dvd://$DVD_TITLE_NUMBER"

		echo -ne "*************************************\n"
		echo "Title $DVD_TITLE_NUMBER Tracks:"
		lsdvd -t $DVD_TITLE_NUMBER -acsv $DVD_PATH 2>/dev/null | grep -E "Subtitle|Audio|VTS" > DVD-lsdvd-T$DVD_TITLE_NUMBER.info
		grep VTS DVD-lsdvd-T$DVD_TITLE_NUMBER.info
		lsdvd-decode DVD-lsdvd-T$DVD_TITLE_NUMBER.info

		echo "Note: For multiple Title crop detection, set VIDEO_TYPE to SHOW and DVD_EPISODES_ORG to TITLES"
	fi

	# choice to copy DVD to iso file
	DVD_MOUNT_PATH=`mount | grep udf | cut -d ' ' -f 3`
	DVD_MOUNT_NAME=`echo $DVD_MOUNT_PATH | cut -d '/' -f 3`
	echo -ne "*************************************\n"
	echo -ne " Wanna copy $DVD_MOUNT_PATH to $SOURCE_DIRECTORY/$ISO_FILE file ? (N/y)\n"
	read answer
	case $answer in
	y* | Y* )
		copy-dvd2iso
		echo -ne "\n You can now use ISO instead of DVD in configuration file."
		;;
	* )
		echo -ne "Skip DVD copy.\n"
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
	echo " lsdvd informations"
	lsdvd -acsv "$ISO_FILE_PATH" 2>/dev/null > ISO-lsdvd.info
	echo "-> see ISO-lsdvd.info"
	
	echo -ne "*************************************\n"
	echo " MPlayer informations"
	mplayer -v -vo null -ao null -frames 0 -identify "$ISO_FILE_PATH" 2>/dev/null > ISO-mplayer.info
	echo "-> see ISO-mplayer.info"

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
	echo "Tested iso:\"$ISO_FILE_PATH\""
	grep "^Disc Title" ISO-lsdvd.info
	DVD_TITLE_NUMBER=`grep "^Longest track:" ISO-lsdvd.info | sed s/'Longest track: '//`
	if  [[ $VIDEO_TYPE == "SHOW" && $DVD_EPISODES_ORG == "TITLES" ]]; then
		for DVD_TITLE_NUMBER in $DVD_TITLE_LIST
		do
			echo "######### Title: $DVD_TITLE_NUMBER #########"
			lsdvd -t $DVD_TITLE_NUMBER -acsv "$ISO_FILE_PATH" 2>/dev/null | grep -E "Subtitle|Audio|VTS" > ISO-lsdvd-T$DVD_TITLE_NUMBER.info
			echo `grep "Title: " ISO-lsdvd-T$DVD_TITLE_NUMBER.info | cut -d "," -f 2`
			cropdetect "-dvd-device $ISO_FILE_PATH dvd://$DVD_TITLE_NUMBER"
			grep VTS ISO-lsdvd-T$DVD_TITLE_NUMBER.info
			lsdvd-decode ISO-lsdvd-T$DVD_TITLE_NUMBER.info
		done
	else
		echo "Longest track chosen for crop detection: Title $DVD_TITLE_NUMBER"
		echo `grep "Title: $DVD_TITLE_NUMBER" ISO-lsdvd.info | cut -d "," -f 2`
		cropdetect "-dvd-device $ISO_FILE_PATH dvd://$DVD_TITLE_NUMBER"

		echo -ne "*************************************\n"
		echo "Title $DVD_TITLE_NUMBER Tracks:"
		lsdvd -t $DVD_TITLE_NUMBER -acsv "$ISO_FILE_PATH" 2>/dev/null | grep -E "Subtitle|Audio|VTS" > ISO-lsdvd-T$DVD_TITLE_NUMBER.info
		grep VTS ISO-lsdvd-T$DVD_TITLE_NUMBER.info
		lsdvd-decode ISO-lsdvd-T$DVD_TITLE_NUMBER.info

		# not so interesting
		#avconv-decode ISO-avconv.info

		echo "Note: For multiple Title crop detection, set VIDEO_TYPE to SHOW and DVD_EPISODES_ORG to TITLES"
	fi
	;;
* )
        echo -ne "\n Media source problem: make sure you filled DVD, ISO or BD in configuration file\n"
        exit 1
        ;;
esac

# IMDb: get ID and download poster image
echo -ne "*************************************\n"
echo -ne "\n Try to get IMDb ID with $TITLE_NAME ($DATE)  ? (Y/n)\n"
read IMDB_ANSWER
case $IMDB_ANSWER in
N* | n* )
	echo -ne " Skip IMDb informations.\n"
	;;
* )
	# get response
	get_imdb_response_title
	if  [[ $IMDB_RESPONSE == "False" ]]; then
		echo -ne " No IMdb informations found ! Try with another release date (first season release date for show)\n"
		echo -ne " Or directly search at http://www.imdb.com -> IMdb ID is XXXXXXXXX in URL: http://www.imdb.com/title/XXXXXXXXX \n"
	else
		get_imdb_id
		echo -ne " IMdb ID seems to be $IMDB_ID\n"
		echo -ne " -> Please check in http://www.imdb.com/title/$IMDB_ID\n"
		echo -ne "*************************************\n"

		# download cover or not
		echo -ne "*************************************\n"
		echo -ne "\n Download $TITLE_NAME ($DATE) IMDb cover ? (N/y)\n"
		read IMDB_ANSWER
		case $IMDB_ANSWER in
		Y* | y* )
			download_imdb_poster
			;;
		* )
			echo -ne " Skip IMDb cover download.\n"
			;;
		esac
		echo -ne "*************************************\n"
	fi
	;;
esac


exit 0