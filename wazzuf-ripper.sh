#! /bin/bash
# Wazzuf Ripper
# DVD/BD rip script
# booloki@gmail.com

CONF_FILE="wazzuf-ripper.conf"
TEMPLATES_PATH="wazzuf-ripper-templates"
FUNCTIONS_PATH="wazzuf-ripper-functions"
FUNCTIONS_AUDIO_FILE="$FUNCTIONS_PATH/wazzuf-functions-audio"
FUNCTIONS_VIDEO_FILE="$FUNCTIONS_PATH/wazzuf-functions-video"
FUNCTIONS_SUBTITLES_FILE="$FUNCTIONS_PATH/wazzuf-functions-subtitle"
FUNCTIONS_COVERART_FILES="$FUNCTIONS_PATH/wazzuf-functions-coverart"
FUNCTIONS_CHECK="$FUNCTIONS_PATH/wazzuf-functions-check"
WAZZUF_FILES="$CONF_FILE $FUNCTIONS_AUDIO_FILE $FUNCTIONS_VIDEO_FILE $FUNCTIONS_SUBTITLES_FILE $FUNCTIONS_COVERART_FILES"

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
DUMP )
	CODEC_AUDIO_1=$AUDIO_1_SOURCE
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
	DUMP )
		CODEC_AUDIO_2=$AUDIO_2_SOURCE
		;;
	AC3 | AC351 | AC320 )
		CODEC_AUDIO_2="AC3"
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


case $VIDEO_TYPE in
MOVIE )
	TITLE_LONG=$TITLE_NAME
	EPISODE_FIRST="1"
	EPISODE_LAST="1"
        ;;
SHOW )
	SEASON_DENOMINATION="Season"
	TITLE_LONG="$TITLE_NAME - $SEASON_DENOMINATION $SEASON_NUMBER"
        ;;
MUSIC )
	TITLE_LONG="$ARTIST_NAME - $TITLE_NAME"
	EPISODE_FIRST="1"
	EPISODE_LAST="1"
        ;;
* )
	echo -ne "\n *************************************\n"
	echo " VIDEO_TYPE not set to MOVIE, SHOW or MUSIC ! Exiting..."
	echo -ne " *************************************\n"
	exit 1
        ;;
esac


echo -ne "\n *************************************\n"
echo " Starting $TITLE_LONG $TAG_RIP with $CODEC_VIDEO and $CODEC_AUDIO_1 $CODEC_AUDIO_2"
echo -ne " *************************************\n"

# Check if source is OK (DVD/ISO only)
# Output VIDEO_BITRATE choice
case $SOURCE in
BD )
	VIDEO_BITRATE=$BDRIP_VIDEO_BITRATE
        ;;
DVD )
	# TOCOMMENT if DVD NAME contains spaces...
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

time for ((i=$EPISODE_FIRST; i <= EPISODE_LAST ; i++))
do

	# check multichapters and set chapters merge informations
	case $MULTICHAP_FORCE in
		y* | Y* )
			CHAPTERS="$MULTICHAP_FIRST-$MULTICHAP_LAST"
			case $SOURCE in
			DVD | ISO )
				MERGE_CHAPTERS="--chapters $CHAPTERS_FILE"
				;;
			* )
				MERGE_CHAPTERS=""
				;;
			esac
			;;
		* )
			CHAPTERS="$i-$i"
			MERGE_CHAPTERS=""
			;;
	esac

	# tagging / set full working file and video filenames
	case $VIDEO_TYPE in
	MOVIE )
		BASE_WORKING_FILE=$TAG_TITLE_NAME.$DATE
		VOB_FILE="$BASE_WORKING_FILE.vob"
		CHAPTERS_FILE="$BASE_WORKING_FILE-chapters.txt"
		XVID_FILE="$BASE_WORKING_FILE.xvid"
		H264_FILE="$BASE_WORKING_FILE.h264"
		DUMP_FILE="$BASE_WORKING_FILE.mpv"
		TAG_AUDIO_CODEC=$CODEC_AUDIO_1
		MERGE_OUTPUT="$BASE_WORKING_FILE.$TAG_RIP.$CODEC_VIDEO.$TAG_AUDIO_CODEC.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
		MERGE_TITLE=$TITLE_NAME
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME ($DATE)"
		echo -ne " *************************************\n"
		;;
	MUSIC )
		BASE_WORKING_FILE=$TAG_TITLE_NAME.$DATE
		VOB_FILE="$BASE_WORKING_FILE.vob"
		CHAPTERS_FILE="$BASE_WORKING_FILE-chapters.txt"
		XVID_FILE="$BASE_WORKING_FILE.xvid"
		H264_FILE="$BASE_WORKING_FILE.h264"
		DUMP_FILE="$BASE_WORKING_FILE.mpv"
		TAG_AUDIO_CODEC=$CODEC_AUDIO_1
		MERGE_OUTPUT="$BASE_WORKING_FILE.$TAG_RIP.$CODEC_VIDEO.$TAG_AUDIO_CODEC.$TAG_AUDIO.$TAG_SIGNATURE.mkv"
		MERGE_TITLE=$TITLE_NAME
		echo -ne "\n *************************************\n"
		echo " Work in progress: $ARTIST_NAME - $TITLE_NAME ($DATE)"
		echo -ne " *************************************\n"
		;;
	SHOW )
		SEASON_TYPE="S"
		EPISODE_TYPE="E"
		BASE_WORKING_FILE="$TAG_TITLE_NAME.$SEASON_TYPE$SEASON_NUMBER.$EPISODE_TYPE$i"
		VOB_FILE="$BASE_WORKING_FILE.vob"
		CHAPTERS_FILE="$BASE_WORKING_FILE-chapters.txt"
		XVID_FILE="$BASE_WORKING_FILE.xvid"
		H264_FILE="$BASE_WORKING_FILE.h264"
		DUMP_FILE="$BASE_WORKING_FILE.mpv"

		if [ ! -f $SOURCE_DIRECTORY/$EPISODES_FILE ]
		then
			echo -ne "\n *************************************\n"
			echo " Warning ! $SOURCE_DIRECTORY/$EPISODES_FILE does not exists !" && sleep 2
			echo -ne " *************************************\n"
			EPISODE_NAME_FULL=$i
			EPISODE_NAME=$i
			EPISODE_NUMBER=$i
			EPISODE_TAG=E$EPISODE_NUMBER
		else
			EPISODE_NAME_FULL=`head -n $i $SOURCE_DIRECTORY/$EPISODES_FILE | tail -n 1`
			EPISODE_NAME=`echo $EPISODE_NAME_FULL | cut -d '-' -f 2-10 | sed s/\ //`
			EPISODE_NUMBER=`echo $EPISODE_NAME_FULL | cut -d '-' -f 1 | sed s/\ //`
			EPISODE_TAG=$EPISODE_TYPE$EPISODE_NUMBER.`echo $EPISODE_NAME | sed s/\ /./g`
		fi
		MERGE_OUTPUT="$TAG_TITLE_NAME.$SEASON_TYPE$SEASON_NUMBER.$EPISODE_TAG.$TAG_RIP.$CODEC_VIDEO.$TAG_AUDIO.$TAG_SIGNATURE.mkv"

		EPISODE_DENOMINATION="Episode"
		MERGE_TITLE="$TITLE_LONG - $EPISODE_DENOMINATION $EPISODE_NAME_FULL"
		echo -ne "\n *************************************\n"
		echo " Work in progress: $EPISODE_DENOMINATION $EPISODE_NAME_FULL"
		echo -ne " *************************************\n"
		;;
	esac


	# Extract full working file (.vob or .m2ts)
	# Save chapters informations (DVD only)
	check_mplayer
	trap "echo -e '\nManual killed script (Ctrl-C) during extracting working file' && exit 1" 2
	case $SOURCE in
	DVD )
		case $MULTICHAP_FORCE in
			y* | Y* )
	                	echo -ne "\n *************************************\n"
		                if [ ! -f $CHAPTERS_FILE ]; then echo " Creating $CHAPTERS_FILE..."; dvdxchap -t $DVD_TITLE_NUMBER -c $CHAPTERS /dev/dvd > $CHAPTERS_FILE; fi
	        	        echo -ne " *************************************\n"
				;;
			* )
	                	echo -ne "\n *************************************\n"
		                echo " No chapters file to create. Next..."
	        	        echo -ne " *************************************\n"
				;;
		esac

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
		case $MULTICHAP_FORCE in
			y* | Y* )
	                	echo -ne "\n *************************************\n"
		                if [ ! -f $CHAPTERS_FILE ]; then echo " Creating $CHAPTERS_FILE..."; dvdxchap -t $DVD_TITLE_NUMBER -c $CHAPTERS $SOURCE_DIRECTORY/$ISO_FILE > $CHAPTERS_FILE; fi
	        	        echo -ne " *************************************\n"
				;;
			* )
	                	echo -ne "\n *************************************\n"
		                echo " No chapters file to create. Next..."
	        	        echo -ne " *************************************\n"
				;;
		esac

		if [ ! -f $VOB_FILE ]; then
			ionice -c $IONICENESS nice -n $NICENESS mplayer -dvd-device $SOURCE_DIRECTORY/$ISO_FILE -dumpstream dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS -dumpfile $VOB_FILE
		else
	                echo -ne "\n *************************************\n"
	                echo " $VOB_FILE file exists. Next..."  && sleep 1
        	        echo -ne " *************************************\n"
		fi
		SOURCE_FILE=$VOB_FILE
	        ;;
	BD )
		SOURCE_FILE=$SOURCE_DIRECTORY/$M2TS_FILE
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
		SUBTITLE_FILE_FORCE_PATH=$SOURCE_DIRECTORY/$SUBTITLE_1_FILE_FORCE

		# subtitle file (force external or not)
		if [[ $SUBTITLE_1_FILE_FORCE == "" ]]; then
			SUBTITLE_SID=$SUBTITLE_1_SID
			SUB_FILE="$BASE_WORKING_FILE.$SUBTITLE_SID-$SUBTITLE_LANG"
			SUBTITLE_FILE=$SUB_FILE.idx
			subtitle_rip
		else
			# check srt files encoding
			if  [[ `echo $SUBTITLE_1_FILE_FORCE | grep -vE ".srt$"` == "" ]]; then subtitle_srt_check; fi
			SUBTITLE_FILE=$SUBTITLE_FILE_FORCE_PATH
		fi
	
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
			SUBTITLE_FILE_FORCE_PATH=$SOURCE_DIRECTORY/$SUBTITLE_2_FILE_FORCE
		
			# subtitle file (force external or not)
			if [[ $SUBTITLE_2_FILE_FORCE == "" ]]; then
				SUBTITLE_SID=$SUBTITLE_2_SID
				SUB_FILE="$BASE_WORKING_FILE.$SUBTITLE_SID-$SUBTITLE_LANG"
				SUBTITLE_FILE=$SUB_FILE.idx
				subtitle_rip
			else
				# check srt files encoding
				if  [[ `echo $SUBTITLE_1_FILE_FORCE | grep -vE ".srt$"` == "" ]]; then subtitle_srt_check; fi
				SUBTITLE_FILE=$SUBTITLE_FILE_FORCE_PATH
			fi

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
	DTS_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.dts"
	WAV_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.wav"
	MP3_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.mp3"
	OGG_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.ogg"
	AC3_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.ac3"

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
		DTS_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.dts"
		WAV_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.wav"
		MP3_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.mp3"
		OGG_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.ogg"
		AC3_FILE="$BASE_WORKING_FILE.$AUDIO_AID-$AUDIO_LANG.ac3"

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


	## Cover art
	# Matroska Cover Art Guidelines http://www.matroska.org/technical/cover_art/index.html
	if [[ $SOURCE_DIRECTORY/$COVER == "" ]]; then
		echo -ne "\n *************************************\n"
		echo " No image attachment. Skipping..." && sleep 1
	        echo -ne " *************************************\n"
		MERGE_COVER=""
	else
		if [ ! -f $SOURCE_DIRECTORY/$COVER ]; then
			echo -ne "\n *************************************\n"
			echo " Warning ! $SOURCE_DIRECTORY/$COVER file does not exists! Skipping..." && sleep 2
	        	echo -ne " *************************************\n"
			MERGE_COVER=""		
		else
			check_imagemagick
			# MIME types detection
			# "The pictures should only use the JPEG and PNG picture formats", Matroska Cover Art Guidelines
			# List of officially recognized image MIME types at the IANA homepage http://www.iana.org/assignments/media-types/image/index.html
			COVER_FORMAT_TEST=`file $SOURCE_DIRECTORY/$COVER | cut -d ' ' -f 2`
			if [[ $COVER_FORMAT_TEST == "JPEG" ]]; then
				COVER_FORMAT=jpeg
				COVER_HEIGHT=`convert $SOURCE_DIRECTORY/$COVER -print "%h" /dev/null`
				COVER_WIDTH=`convert $SOURCE_DIRECTORY/$COVER -print "%w" /dev/null`
				cover_art_convert
			else
				if [[ $COVER_FORMAT_TEST == "PNG" ]]; then
					COVER_FORMAT=png
					COVER_HEIGHT=`file $SOURCE_DIRECTORY/$COVER | cut -d "," -f 2 | cut -d " " -f 4`
					COVER_WIDTH=`file $SOURCE_DIRECTORY/$COVER | cut -d "," -f 2 | cut -d " " -f 2`
					cover_art_convert
				else
					echo -ne "\n *************************************\n"
					echo " $COVER file format unrecognized, so no image attachment. Next... " && sleep 2
			        	echo -ne " *************************************\n"
					MERGE_COVER=""		
				fi
			fi
		fi
	fi


	## xml tags
	# http://matroska.org/technical/specs/tagging/index.html
	TAG_FILE="$BASE_WORKING_FILE.xml"
	if [ ! -f $TAG_FILE ]; then
		# 3 templates:  tags-50-movie-template.xml  tags-50-music-template.xml  tags-50-show-template.xml
		# in TEMPLATES_PATH
		TEMPLATE_FILE_MOVIE="../$TEMPLATES_PATH/tags-50-movie-template.xml"
		TEMPLATE_FILE_MUSIC="../$TEMPLATES_PATH/tags-50-music-template.xml"
		TEMPLATE_FILE_SHOW="../$TEMPLATES_PATH/tags-50-show-template.xml"

		# if empty tag: ugly but not really important
		XMLTAG_DATE_ENCODED=`date +%Y`
		XMLTAG_ENCODED_BY="$TAG_SIGNATURE"
		XMLTAG_COMMENT="$COMMENT"
		XMLTAG_DATE_RELEASE="$DATE"
		# DATE_TAGGED useless

		xml_tagging
	else
		echo -ne "\n *************************************\n"
		echo " xml tags file exists. Next..."  && sleep 1
		echo -ne " *************************************\n"		
	fi

	# second check, if generation problem, and to fill MERGE_XMLTAGS
	if [ -f $TAG_FILE ]; then
		MERGE_XMLTAGS="--global-tags $TAG_FILE"
	else
		echo -ne "\n *************************************\n"
		echo " xml tags file generation problem. Skipping..."  && sleep 2
		echo -ne " *************************************\n"
		MERGE_XMLTAGS=""
	fi


	## merge
	trap "echo -e '\nManual killed script (Ctrl-C) during final mkv merge' && exit 1" 2

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
		$MERGE_COVER \
		$MERGE_XMLTAGS

done

cd ..
echo -ne "\n *************************************\n"
echo " $TITLE_LONG $TAG_RIP Finished"
echo -ne " *************************************\n"

exit 0
