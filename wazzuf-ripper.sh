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


# entering working directory
mkdir -p "$TAG_TITLE_NAME"
cd $TAG_TITLE_NAME

echo -ne "\n *************************************\n"
echo " Starting $TITLE_LONG $TAG_RIP with $CODEC_VIDEO and $CODEC_AUDIO_1 $CODEC_AUDIO_2"
echo -ne " *************************************\n"

# Read and save chapters list (DVD only)
# output VIDEO_BITRATE choice (BD or DVD+*)
case $SOURCE in
BD )
	VIDEO_BITRATE=$BDRIP_VIDEO_BITRATE
        ;;
DVD )
	VIDEO_BITRATE=$DVDRIP_VIDEO_BITRATE
	check_ogmtools
	dvdxchap -t $DVD_TITLE_NUMBER /dev/dvd > title$DVD_TITLE_NUMBER-chapters.txt
        ;;
ISO )	
	if [ -f $ISO_FILE ]
	then
		check_ogmtools
		dvdxchap -t $DVD_TITLE_NUMBER $ISO_FILE > title$DVD_TITLE_NUMBER-chapters.txt
	else
		echo -ne "\n *************************************\n"
		echo " ISO_FILE $ISO_FILE does not exists ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
	fi
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
if [[ $SERIE == "no" ]]; then EPISODE_LAST="1"; fi

time for ((i=$EPISODE_FIRST; i <= EPISODE_LAST ; i++))
do
	# check multichapers
	case $MULTICHAP_FORCE in
		y* | Y* )
			CHAPTERS="$MULTICHAP_FIRST-$MULTICHAP_LAST"
			;;
		* )
			CHAPTERS="$i-$i"
			;;
	esac

	# set video and subtitles variables if series or not 
	case $SERIE in
	y* | Y* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE E$i"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.E$i.vob"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.E$i.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.E$i.h264"
		SUB_FILE="$TAG_TITLE_NAME.$DATE.E$i.$SUBTITLE_SID-$SUBTITLE_LANG"
		;;
	n* | N* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.vob"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.h264"
		SUB_FILE="$TAG_TITLE_NAME.$DATE.$SUBTITLE_SID-$SUBTITLE_LANG"
		;;
	* )
                echo -ne "\n *************************************\n"
		echo " SERIE not set to "yes" or "no" ! Exiting..."
                echo -ne " *************************************\n"
		exit 1
		;;
	esac


	# Extract Full working file (.vob or .m2ts)
	check_mplayer
	case $SOURCE in
	DVD )
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


	## subtitle extract
	subtitle_rip


	## Audio extract/encode

	# audio track 1
	AUDIO_AID=$AUDIO_1_AID
	AUDIO_SOURCE=$AUDIO_1_SOURCE
	AUDIO_LANG=$AUDIO_1_LANG
	AUDIO_NAME=$AUDIO_1_NAME
	CODEC_AUDIO=$CODEC_AUDIO_1

	# set audio variables if series or not 
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
	MERGE_AUDIO_1="--language 0:$AUDIO_1_LANG --track-name 0:$AUDIO_1_NAME $AUDIO_FILE"

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
		MERGE_AUDIO_2="--language 0:$AUDIO_2_LANG --track-name 0:$AUDIO_2_NAME $AUDIO_FILE"
	fi
	
	MERGE_AUDIO="$MERGE_AUDIO_1 $MERGE_AUDIO_2"


	## video encode
	video_rip
	MERGE_VIDEO="--aspect-ratio 0:$VIDEO_RATIO $VIDEO_FILE"


	## merge

	# aspect-ratio check
	case $VIDEO_RATIO in
	4/3 | 1.33 | 16/9 | 1.78 | 2.21 )
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
				MERGE_OUTPUT="-o $TAG_TITLE_NAME.$DATE$EPISODE_TAG.$TAG_RIP.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
				#.$CODEC_VIDEO.$CODEC_AUDIO
				MERGE_TITLE="$TITLE_LONG - $EPISODE_NAME"
				;;
			* )	
				MERGE_OUTPUT="-o $TAG_TITLE_NAME.$DATE.$TAG_RIP.$CODEC_VIDEO.$CODEC_AUDIO.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
				MERGE_TITLE=$TITLE_LONG
				;;
		esac


		# global merge command
		echo -ne "\n *************************************\n"
		echo " Final file merge:"
		echo -ne " *************************************\n"
		check_mkvmerge
		nice -n $NICENESS mkvmerge \
			$MERGE_OUTPUT --title "$MERGE_TITLE" \
			$MERGE_VIDEO \
			$MERGE_AUDIO \
			$MERGE_SUBTITLES
		;;
	* )
		echo -ne "\n *************************************\n"
		echo " $VIDEO_RATIO : video aspect ratio not recognized ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
		;;
	esac
done

cd ..
echo -ne "\n *************************************\n"
echo " $TITLE_LONG $TAG_RIP Finished"
echo -ne " *************************************\n"

exit 0
