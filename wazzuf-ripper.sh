#! /bin/bash
# Wazzuf Ripper
# DVD/BD rip script
# booloki@gmail.com

CONF_FILE="wazzuf-ripper.conf"
FUNCTIONS_PATH="wazzuf-ripper-functions"
FUNCTIONS_AUDIO_FILE="$FUNCTIONS_PATH/wazzuf-functions-audio"
FUNCTIONS_VIDEO_FILE="$FUNCTIONS_PATH/wazzuf-functions-video"
FUNCTIONS_SUBTITLES_FILE="$FUNCTIONS_PATH/wazzuf-functions-subtitle"
FUNCTIONS_CHECK="$FUNCTIONS_PATH/wazzuf-functions-check"
WAZZUF_FILES="$CONF_FILE $FUNCTIONS_AUDIO_FILE $FUNCTIONS_VIDEO_FILE $FUNCTIONS_SUBTITLES_FILE"

# basic error catching
trap "echo -e '\nWazzuf Ripper failed !' && exit 1" 15

# check wazzuf files
source $FUNCTIONS_CHECK
checkandsource_wazzuf_files

# video codec choice check
case $1 in
h264 | x264 | H264 | X264 )
        CODEC_VIDEO="H264"
        ;;
xvi* | Xvi* | XVI* )
        CODEC_VIDEO="XVID"
        ;;
dump | DUMP )
        CODEC_VIDEO="DUMP"
        ;;
"" )
	# use default CODEC_VIDEO
	CODEC_VIDEO=$DEFAULT_CODEC_VIDEO
	;;
* )
        wazzuf_usage
        ;;
esac

# audio 1 codec choice check
case $2 in
DTS | DTS-HD )
        CODEC_AUDIO_1=$2
        ;;
AC3 | AC351 | AC320 )
        CODEC_AUDIO_1=$2
        ;;
ogg | vorbis | OGG | VORBIS )
        CODEC_AUDIO_1="VORBIS"
        ;;
mp3 | MP3 | Mp3 )
        CODEC_AUDIO_1="MP3"
        ;;
"" )
        # use default CODEC_AUDIO
	CODEC_AUDIO_1=$DEFAULT_CODEC_AUDIO
        ;;
* )
        wazzuf_usage
        ;;
esac

# audio 2 codec choice check
if [[ ! $AUDIO_2_LANG == "" ]]; then
	case $3 in
	DTS | DTS-HD )
	        CODEC_AUDIO_2=$2
	        ;;
	AC3 | AC351 | AC320 )
	        CODEC_AUDIO_2=$2
	        ;;
	ogg | vorbis | OGG | VORBIS )
	        CODEC_AUDIO_2="VORBIS"
	        ;;
	mp3 | MP3 | Mp3 )
	        CODEC_AUDIO_2="MP3"
	        ;;
	* )
	        # use default CODEC_AUDIO
		CODEC_AUDIO_2=$DEFAULT_CODEC_AUDIO
	        ;;
	esac
else
	CODEC_AUDIO_2=""
fi


# enter working directory
mkdir -p "$TAG_TITLE_NAME"
cd $TAG_TITLE_NAME

echo -ne "\n *************************************\n"
echo " Starting $TITLE_LONG $TAG_RIP with $CODEC_VIDEO and $CODEC_AUDIO_1 $CODEC_AUDIO_2"
echo -ne " *************************************\n"

# Check if source is OK (DVD only)
# output VIDEO_BITRATE choice (BD or DVD+*)
case $SOURCE in
BD )
	VIDEO_BITRATE=$BDRIP_VIDEO_BITRATE
        ;;
DVD )
	# check_dvd TOCOMMENT if DVD NAME contains spaces...
	check_dvd DVD
	check_ogmtools
	VIDEO_BITRATE=$DVDRIP_VIDEO_BITRATE
        ;;
ISO )	
	check_dvd ISO
	check_ogmtools
	VIDEO_BITRATE=$DVDRIP_VIDEO_BITRATE
	;;
* )
        echo -ne "\n Media source problem: make sure you filled DVD ISO or BD in configuration file\n"
        exit 1
        ;;
esac

check_nice
check_ionice

# serie check for loop
if [[ $SERIE == "no" ]]; then EPISODE_LAST="1"; EPISODE_FIRST="1"; fi

time for ((i=$EPISODE_FIRST; i <= EPISODE_LAST ; i++))
do
	# check multichapters
	case $MULTICHAP_FORCE in
		y* | Y* )
			CHAPTERS="$MULTICHAP_FIRST-$MULTICHAP_LAST"
			;;
		* )
			CHAPTERS="$i-$i"
			;;
	esac

	# set full working file and video filenames if series or not 
	case $SERIE in
	y* | Y* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE E$i"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.E$i.vob"
		CHAPTERS_FILE="$TAG_TITLE_NAME.$DATE.E$i-chapters.txt"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.E$i.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.E$i.h264"
		DUMP_FILE="$TAG_TITLE_NAME.$DATE.E$i.mpv"
		;;
	n* | N* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.vob"
		CHAPTERS_FILE="$TAG_TITLE_NAME.$DATE-chapters.txt"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.h264"
		DUMP_FILE="$TAG_TITLE_NAME.$DATE.mpv"
		;;
	* )
                echo -ne "\n *************************************\n"
		echo " SERIE not set to "yes" or "no" ! Exiting..."
                echo -ne " *************************************\n"
		exit 1
		;;
	esac


	# Extract full working file (.vob or .m2ts)
	# Save chapters informations (DVD only)
	check_mplayer
	trap "echo -e '\nManual killed script (Ctrl-C) during extracting working file' && exit 1" 2
	case $SOURCE in
	DVD )
		if [ ! -f $CHAPTERS_FILE ]; then dvdxchap -t $DVD_TITLE_NUMBER -c $CHAPTERS /dev/dvd > $CHAPTERS_FILE; fi

		if [ ! -f $VOB_FILE ]; then
                	# extract local working file from DVD
	               ionice -c $IONICENESS nice -n $NICENESS mplayer -dumpstream dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS -dumpfile $VOB_FILE
		else
	                echo -ne "\n *************************************\n"
	                echo " $VOB_FILE file exists. Next..."  && sleep 1
        	        echo -ne " *************************************\n"
		fi
		SOURCE_FILE=$VOB_FILE
	        ;;
	ISO )
		if [ ! -f $CHAPTERS_FILE ]; then dvdxchap -t $DVD_TITLE_NUMBER -c $CHAPTERS $ISO_FILE > $CHAPTERS_FILE; fi

		if [ ! -f $VOB_FILE ]; then
			ionice -c $IONICENESS nice -n $NICENESS mplayer -dvd-device $ISO_FILE -dumpstream dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS -dumpfile $VOB_FILE
		else
	                echo -ne "\n *************************************\n"
	                echo " $VOB_FILE file exists. Next..."  && sleep 1
        	        echo -ne " *************************************\n"
		fi
		SOURCE_FILE=$VOB_FILE
	        ;;
	BD )
		SOURCE_FILE=$M2TS_FILE
		;;
	esac


	## subtitle(s) check/extract
	trap "echo -e '\nManual killed script (Ctrl-C) during checking/extracting subtitles' && exit 1" 2
	if [[ $SUBTITLE_1_LANG == "" ]]; then
		echo -ne "\n *************************************\n"
		echo " No subtitle track choice, next..." && sleep 1
		echo -ne " *************************************\n"
	else
		# subtitle track 1
		SUBTITLE_LANG=$SUBTITLE_1_LANG
		SUBTITLE_NAME=$SUBTITLE_1_NAME
		SUBTITLE_SID=$SUBTITLE_1_SID
		SUBTITLE_FILE=$SUBTITLE_1_FILE
	
		# set subtitles filenames if series or not 
		case $SERIE in
		y* | Y* )
			SUB_FILE="$TAG_TITLE_NAME.$DATE.E$i.$SUBTITLE_SID-$SUBTITLE_LANG"
			;;
		n* | N* )
			SUB_FILE="$TAG_TITLE_NAME.$DATE.$SUBTITLE_SID-$SUBTITLE_LANG"
			;;
		esac
	
		subtitle_rip
	
		# Force no default subtitle (or not)
		case $SUBTITLE_NODEFAULT_FORCE in
		Y* | y* )
			MERGE_SUBTITLES_1="--language 0:$SUBTITLE_LANG --default-track 0:0 --track-name 0:$SUBTITLE_NAME $SUBTITLE_FILE"
			;;
		* )
			MERGE_SUBTITLES_1="--language 0:$SUBTITLE_LANG --track-name 0:$SUBTITLE_NAME $SUBTITLE_FILE"
			;;
		esac
		
		# subtitle track 2
		if [[ $SUBTITLE_2_LANG == "" ]]; then
			echo -ne "\n *************************************\n"
			echo " No second subtitle track choice. Next..." && sleep 1
	        	echo -ne " *************************************\n"
		else
			SUBTITLE_LANG=$SUBTITLE_2_LANG
			SUBTITLE_NAME=$SUBTITLE_2_NAME
			SUBTITLE_SID=$SUBTITLE_2_SID
			SUBTITLE_FILE=$SUBTITLE_2_FILE
		
			# set subtitles filenames if series or not 
			case $SERIE in
			y* | Y* )
				SUB_FILE="$TAG_TITLE_NAME.$DATE.E$i.$SUBTITLE_SID-$SUBTITLE_LANG"
				;;
			n* | N* )
				SUB_FILE="$TAG_TITLE_NAME.$DATE.$SUBTITLE_SID-$SUBTITLE_LANG"
				;;
			esac

			subtitle_rip

			# Force no default subtitle (or not)
			case $SUBTITLE_NODEFAULT_FORCE in
			Y* | y* )
				MERGE_SUBTITLES_2="--language 0:$SUBTITLE_LANG --default-track 0:0 --track-name 0:$SUBTITLE_NAME $SUBTITLE_FILE"
				;;
			* )
				MERGE_SUBTITLES_2="--language 0:$SUBTITLE_LANG --track-name 0:$SUBTITLE_NAME $SUBTITLE_FILE"
				;;
			esac
		fi

		MERGE_SUBTITLES_FULL="$MERGE_SUBTITLES_1 $MERGE_SUBTITLES_2"
	fi


	## Audio track(s) extract/encode
	trap "echo -e '\nManual killed script (Ctrl-C) during Audio track(s) extracting/encoding' && exit 1" 2

	# audio track 1
	AUDIO_AID=$AUDIO_1_AID
	AUDIO_SOURCE=$AUDIO_1_SOURCE
	AUDIO_LANG=$AUDIO_1_LANG
	AUDIO_NAME=$AUDIO_1_NAME
	CODEC_AUDIO=$CODEC_AUDIO_1

	# set audio filenames if series or not 
	case $SERIE in
	y* | Y* )
		DTS_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.dts"
		WAV_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.wav"
		MP3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.mp3"
		OGG_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ogg"
		AC3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ac3"
		;;
	n* | N* )
		DTS_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.dts"
		WAV_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.wav"
		MP3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.mp3"
		OGG_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ogg"
		AC3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ac3"
		;;
	esac

	audio_rip

	# merge with or without audio sync
	if [[ $AUDIO_1_SYNC == "" ]]; then
		MERGE_AUDIO_1="--language 0:$AUDIO_1_LANG --track-name 0:$AUDIO_1_NAME $AUDIO_FILE"
	else	
		MERGE_AUDIO_1="--language 0:$AUDIO_1_LANG --track-name 0:$AUDIO_1_NAME -y 0:$AUDIO_1_SYNC $AUDIO_FILE"
	fi

	# audio track 2
	if [[ $AUDIO_2_LANG == "" ]]; then
		echo -ne "\n *************************************\n"
		echo " No second audio track choice. Next..."  && sleep 1
        	echo -ne " *************************************\n"
	else
		AUDIO_AID=$AUDIO_2_AID
		AUDIO_SOURCE=$AUDIO_2_SOURCE
		AUDIO_LANG=$AUDIO_2_LANG
		AUDIO_NAME=$AUDIO_2_NAME
		CODEC_AUDIO=$CODEC_AUDIO_2

		# set audio filenames if series or not 
		case $SERIE in
		y* | Y* )
			DTS_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.dts"
			WAV_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.wav"
			MP3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.mp3"
			OGG_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ogg"
			AC3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ac3"
			;;
		n* | N* )
			DTS_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.dts"
			WAV_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.wav"
			MP3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.mp3"
			OGG_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ogg"
			AC3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ac3"
			;;
		esac

		audio_rip

		if [[ $AUDIO_2_SYNC == "" ]]; then
			MERGE_AUDIO_2="--language 0:$AUDIO_2_LANG --track-name 0:$AUDIO_2_NAME $AUDIO_FILE"
		else	
			MERGE_AUDIO_2="--language 0:$AUDIO_2_LANG --track-name 0:$AUDIO_2_NAME -y 0:$AUDIO_2_SYNC $AUDIO_FILE"
		fi					
	fi
	
	MERGE_AUDIO_FULL="$MERGE_AUDIO_1 $MERGE_AUDIO_2"


	## video encode
	trap "echo -e '\nManual killed script (Ctrl-C) during Video encoding' && exit 1" 2

	video_rip

	if [[ $VIDEO_RATIO_FORCE == "" ]]; then
		MERGE_VIDEO="$VIDEO_FILE"
	else
		# aspect-ratio check
		case $VIDEO_RATIO_FORCE in
		4/3 | 1.33 | 16/9 | 1.78 | 2.21 | 2.35 )
			MERGE_VIDEO="--aspect-ratio 0:$VIDEO_RATIO_FORCE $VIDEO_FILE"
			;;
		* )
			echo -ne "\n *************************************\n"
			echo " $VIDEO_RATIO_FORCE : video aspect ratio not recognized ! Exiting..."
			echo -ne " *************************************\n"
			exit 1
			;;
		esac
	fi

	## chapters informations
	case $SOURCE in
	DVD | ISO )
		MERGE_CHAPTERS="--chapters $CHAPTERS_FILE"
		;;
	* )
		MERGE_CHAPTERS=""
		;;
	esac


	## image attachment
	if [[ $COVER == "" ]]; then
		echo -ne "\n *************************************\n"
		echo " No image attachment. Next..." && sleep 1
	        echo -ne " *************************************\n"
		MERGE_COVER=""
	else
		if [ ! -f $COVER ]; then
			echo -ne "\n *************************************\n"
			echo " Warning ! $COVER does not exists !" && sleep 2
	        	echo -ne " *************************************\n"
			MERGE_COVER=""		
		else
			echo -ne "\n *************************************\n"
			echo " $COVER image choice OK. Next... " && sleep 1
        	echo -ne " *************************************\n"
			MERGE_COVER="--attachment-description "cover" --attachment-mime-type image/jpeg --attach-file $COVER"
		fi
	fi


	## merge
	trap "echo -e '\nManual killed script (Ctrl-C) during final mkv merging' && exit 1" 2

	case $SERIE in
		y* | Y* )
			# for TV series
	        	if [ ! -f $EPISODES_FILE ]
		        then
				echo -ne "\n *************************************\n"
		                echo " Warning ! $EPISODES_FILE does not exists !" && sleep 2
	                	echo -ne " *************************************\n"
				EPISODE_NAME="E$i"
				EPISODE_TAG="E$i"
			else
				EPISODE_NAME=`head -n $i $EPISODES_FILE | tail -n 1`
				EPISODE_TAG="E`echo $EPISODE_NAME | sed s/\ -\ /./g | sed s/\ /./g`"
			fi
			MERGE_OUTPUT="$TAG_TITLE_NAME.$DATE$EPISODE_TAG.$TAG_RIP.$CODEC_VIDEO.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
			MERGE_TITLE="$TITLE_LONG - $EPISODE_NAME"
			;;
		* )	
			MERGE_OUTPUT="$TAG_TITLE_NAME.$DATE.$TAG_RIP.$CODEC_VIDEO.$CODEC_AUDIO.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
			MERGE_TITLE=$TITLE_LONG
			;;
	esac


	# global merge command
	echo -ne "\n *************************************\n"
	echo " Final file merge:"
	echo -ne " *************************************\n"
	check_mkvmerge
	nice -n $NICENESS mkvmerge \
		-o $MERGE_OUTPUT --title "$MERGE_TITLE" \
		$MERGE_VIDEO \
		$MERGE_AUDIO_FULL \
		$MERGE_SUBTITLES_FULL \
		$MERGE_CHAPTERS \
		$MERGE_COVER

done

cd ..
echo -ne "\n *************************************\n"
echo " $TITLE_LONG $TAG_RIP Finished"
echo -ne " *************************************\n"

exit 0
