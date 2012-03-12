#! /bin/bash
# Wazzuf Ripper
# DVD/BD rip script
# booloki@gmail.com

## check conf file
CONF_FILE="wazzuf-ripper.conf"
if [ ! -f $CONF_FILE ]; then
	echo -ne "\n No configuration file found ! Where is $CONF_FILE ? Exiting...\n"
        exit 1
else	
	source $CONF_FILE
fi

# video codec filled
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
        echo -ne "\n Syntax : $0 [Video Codec (h264,xvid)] [Audio Codec (DTS,AC3,vorbis,mp3)]\n"
        exit 1
        ;;
esac

# audio codec filled
case $2 in
DTS | DTS-HD )
        CODEC_AUDIO=$2
        ;;
AC3 | AC351 | AC320 )
        CODEC_AUDIO=$2
        ;;
ogg | vorbis | OGG | VORBIS )
        CODEC_AUDIO="VORBIS"
        ;;
mp3 | MP3 | Mp3 )
        CODEC_AUDIO="MP3"
        ;;
"" )
        # use default CODEC_AUDIO
	CODEC_AUDIO=$DEFAULT_CODEC_AUDIO
        ;;
* )
        echo -ne "\n Syntax : $0 [Video Codec (h264,xvid)] [Audio Codec (DTS,AC3,vorbis,mp3)]\n"
        exit 1
        ;;
esac


# entering working directory
mkdir -p "$TAG_TITLE_NAME"
cd $TAG_TITLE_NAME

echo -ne "\n *************************************\n"
echo " Starting $TITLE_LONG $TAG_RIP with $CODEC_VIDEO and $CODEC_AUDIO"
echo -ne " *************************************\n"

# Read and save chapters list (DVD only)
# output VIDEO_BITRATE choice (BD or DVD+*)
case $SOURCE in
BD )
	VIDEO_BITRATE=$BDRIP_VIDEO_BITRATE
        ;;
DVD )
	VIDEO_BITRATE=$DVDRIP_VIDEO_BITRATE
	dvdxchap -t $DVD_TITLE_NUMBER /dev/dvd > title$DVD_TITLE_NUMBER-chapters.txt
        ;;
ISO )	
	if [ -f $ISO_FILE ]
	then
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

	# set variables if series or not 
	case $SERIE in
	y* | Y* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE E$i"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.E$i.vob"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.E$i.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.E$i.h264"
		SUB_FILE="$TAG_TITLE_NAME.$DATE.E$i.$SUBTITLE_SID-$SUBTITLE_LANG"
		DTS_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.dts"
		WAV_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.wav"
		MP3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.mp3"
		OGG_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ogg"
		AC3_FILE="$TAG_TITLE_NAME.$DATE.E$i.$AUDIO_AID-$AUDIO_LANG.ac3"
		;;
	n* | N* )
		echo -ne "\n *************************************\n"
		echo " Work in progress: $TITLE_NAME $DATE"
	        echo -ne " *************************************\n"
		VOB_FILE="$TAG_TITLE_NAME.$DATE.vob"
		XVID_FILE="$TAG_TITLE_NAME.$DATE.xvid"
		H264_FILE="$TAG_TITLE_NAME.$DATE.h264"
		SUB_FILE="$TAG_TITLE_NAME.$DATE.$SUBTITLE_SID-$SUBTITLE_LANG"
		DTS_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.dts"
		WAV_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.wav"
		MP3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.mp3"
		OGG_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ogg"
		AC3_FILE="$TAG_TITLE_NAME.$DATE.$AUDIO_AID-$AUDIO_LANG.ac3"
		;;
	* )
                echo -ne "\n *************************************\n"
		echo " SERIE not set to "yes" or "no" ! Exiting..."
                echo -ne " *************************************\n"
		exit 1
		;;
	esac

	## subtitle extract
	# DVD only - .idx and .sub files
	case $SUBTITLE_LANG in
	fr | en )
	        case $SOURCE in
	        DVD )
			SUBTITLE_FILE=$SUB_FILE.idx
			if [ -f $SUBTITLE_FILE ]
		        then
				echo -ne "\n *************************************\n"
		                echo " $SUBTITLE_FILE exists. Next..." && sleep 1
		                echo -ne " *************************************\n"
		        else
				echo -ne "\n *************************************\n"
		                echo " Extracting subtitle to $SUBTITLE_FILE "
		                echo -ne " *************************************\n"
				nice -n $NICENESS mencoder dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS \
				-vobsubout $SUB_FILE -vobsuboutindex 0 -sid $SUBTITLE_SID \
				-o /dev/null -nosound -ovc frameno
			fi
			;;
		ISO )
			SUBTITLE_FILE=$SUB_FILE.idx
			if [ -f $SUBTITLE_FILE ]
		        then
				echo -ne "\n *************************************\n"
		                echo " $SUBTITLE_FILE exists. Next..." && sleep 1
		                echo -ne " *************************************\n"
		        else
				echo -ne "\n *************************************\n"
		                echo " Extracting subtitle to $SUBTITLE_FILE "
		                echo -ne " *************************************\n"
				nice -n $NICENESS mencoder -dvd-device $ISO_FILE dvd://$DVD_TITLE_NUMBER -chapter $CHAPTERS \
					-vobsubout $SUB_FILE -vobsuboutindex 0 -sid $SUBTITLE_SID \
					-o /dev/null -nosound -ovc frameno
			fi
			;;
		BD )
			if [ ! -f $SUBTITLE_FILE ]
		        then
				# PSG format (.sup) - subtitle extraction impossible with mplayer 1.0rc4-4.5.2
				echo -ne "\n *************************************\n"
		                echo " $SUBTITLE_FILE does not exists ! Exiting..."
		                echo " For example, extrat PSG subtitles with tsMuxer - http://www.videohelp.com/tools/tsMuxeR "
		                echo -ne " *************************************\n"
				exit 1
			else
				# SUBTITLE_FILE is already OK
				echo -ne "\n *************************************\n"
		                echo " $SUBTITLE_FILE subtitles OK. Next..." && sleep 1
		                echo -ne " *************************************\n"
			fi
			;;
		esac
		MERGE_SUBTITLES="--language 0:$SUBTITLE_LANG --default-track 0:0 --track-name 0:$SUBTITLE_NAME $SUBTITLE_FILE"
		;;
	"" )
		echo -ne "\n *************************************\n"
		echo " No subtitle, next..." && sleep 1
		echo -ne " *************************************\n"
		MERGE_SUBTITLES=""
		;;
	* )
		echo -ne "\n *************************************\n"
		echo " $SUBTITLE_LANG : subtitle code not recognized ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
		;;
	esac

	# Extract Full working file (.vob or .m2ts)
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

	## Audio extract/encode

	# Audio source format
        case $AUDIO_SOURCE in
	DTS )
		AUDIO_SOURCE_FILE=$DTS_FILE
		;;
        AC3 )
		AUDIO_SOURCE_FILE=$AC3_FILE
		;;
	* )
		echo -ne "\n *************************************\n"
		echo " $AUDIO_SOURCE : audio source format not recognized ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
		;;
	esac

	# extract audio from local working file
	case $CODEC_AUDIO in
	DTS | DTS-HD | AC3 | AC351 )
		# extract AC3/DTS
		if [ -f $AUDIO_SOURCE_FILE ]
		then
			echo -ne "\n *************************************\n"
			echo " $DTS_FILE exists, next..." && sleep 1
			echo -ne " *************************************\n"
		else
			ionice -c $IONICENESS nice -n $NICENESS mplayer $SOURCE_FILE -aid $AUDIO_AID -dumpaudio -dumpfile $AUDIO_SOURCE_FILE
		fi
		;;
        VORBIS | MP3 )
		# extract wave
		if [ ! -f $WAV_FILE ]; then
			 # takes a long time....
	                ionice -c $IONICENESS nice -n $NICENESS mplayer $SOURCE_FILE -aid $AUDIO_AID -ao pcm:file=$WAV_FILE -vc null -vo null
		else
	                echo -ne "\n *************************************\n"
	                echo " Wave file exists. Next..."  && sleep 1
        	        echo -ne " *************************************\n"
		fi
                ;;
	* )
		echo -ne "\n *************************************\n"
		echo " $CODEC_AUDIO : audio codec not recognized ! Exiting..."
		echo -ne " *************************************\n"
		exit 1
		;;
        esac

        case $CODEC_AUDIO in
	DTS | DTS-HD )
		AUDIO_FILE=$DTS_FILE
       		if [ -f $AUDIO_FILE ]
       		then
			echo -ne "\n *************************************\n"
			echo " $AUDIO_FILE exists, next..." && sleep 1
			echo -ne " *************************************\n"
		else
			echo -ne "\n *************************************\n"
			echo " $AUDIO_FILE should already exist but not here ! exiting..."
			echo -ne " *************************************\n"
			exit 1	
		fi
		;;
        AC3 | AC351)
		AUDIO_FILE=$AC3_FILE
		if [ -f $AUDIO_FILE ]
		then
			echo -ne "\n *************************************\n"
			echo " $AUDIO_FILE exists, next..." && sleep 1
			echo -ne " *************************************\n"
		else
			# DTS to AC3
			nice -n $NICENESS ffmpeg -threads $AUDIO_AC3_THREADS -i $DTS_FILE -acodec ac3 -ab $AUDIO_AC3_QUAL -y $AUDIO_FILE
		fi
		;;
	VORBIS )
		# audio ogg vorbis encode
		AUDIO_FILE=$OGG_FILE
		if [ -f $AUDIO_FILE ]
	        then
	             	echo -ne "\n *************************************\n"
	                echo " $AUDIO_FILE exists, next..." && sleep 1
        	     	echo -ne " *************************************\n"
	        else
			nice -n $NICENESS oggenc $WAV_FILE -q $AUDIO_OGG_QUAL -o $OGG_FILE
		fi
		;;
	MP3 )
		# audio mp3 encode (but lame not multithreaded...)
		AUDIO_FILE=$MP3_FILE
		if [ -f $AUDIO_FILE ]
	        then
	             	echo -ne "\n *************************************\n"
	                echo " $AUDIO_FILE exists, next..." && sleep 1
        	     	echo -ne " *************************************\n"
	        else
			# lame mode choice
			case $AUDIO_MP3_MODE in
			        CBR | cbr )
					nice -n $NICENESS lame --scale $AUDIO_MP3_VOL -b $AUDIO_MP3_CBR -h $WAV_FILE $AUDIO_FILE
					;;
			        VBR | vbr )
					nice -n $NICENESS lame --scale $AUDIO_MP3_VOL -V $AUDIO_MP3_VBR -h $WAV_FILE $AUDIO_FILE
					;;
			        * )
					echo -ne "\n *************************************\n"
					echo " $AUDIO_MP3_MODE : lame mp3 encoding mode not recognized ! Exiting..."
					echo -ne " *************************************\n"
					exit 1
					;;
			esac
		fi
		;;
	esac

	## video encode
	case $CODEC_VIDEO in
	H264 )
		# video h264 (2 pass) encode
		# doc http://www.mplayerhq.hu/DOCS/HTML/fr/menc-feat-x264.html
		VIDEO_FILE=$H264_FILE
		if [ ! -f $VIDEO_FILE ]; then
			nice -n $NICENESS mencoder $SOURCE_FILE -o $VIDEO_FILE \
				-vf pp=ci,crop=$VIDEO_CROP \
				-ovc x264 -x264encopts bitrate=$VIDEO_BITRATE:frameref=$VIDEO_X264_FRAMEREF_PASS1:mixed_refs:bframes=3:b_adapt:b_pyramid=strict:weight_b:partitions=all:8x8dct:me=umh:subq=$VIDEO_X264_SUBQ_PASS1:trellis=2:threads=$VIDEO_X264_THREADS:pass=1 \
				-nosound -nosub
			nice -n $NICENESS mencoder $SOURCE_FILE -o $VIDEO_FILE \
				-vf pp=ci,crop=$VIDEO_CROP \
				-ovc x264 -x264encopts bitrate=$VIDEO_BITRATE:frameref=$VIDEO_X264_FRAMEREF_PASS2:mixed_refs:bframes=3:b_adapt:b_pyramid=strict:weight_b:partitions=all:8x8dct:me=umh:subq=$VIDEO_X264_SUBQ_PASS2:trellis=2:threads=$VIDEO_X264_THREADS:pass=2 \
				-nosound -nosub
		else
			echo -ne "\n *************************************\n"
	                echo " $VIDEO_FILE file exists. Next...." && sleep 1
	                echo -ne " *************************************\n"
		fi
		;;
	XVID )	
		# video xvid encode
	        # doc http://www.mplayerhq.hu/DOCS/HTML/fr/menc-feat-xvid.html
		VIDEO_FILE=$XVID_FILE
	        if [ -f $VIDEO_FILE ]
	        then
			echo -ne "\n *************************************\n"
	                echo " $VIDEO_FILE file exists. Next..." && sleep 1
	                echo -ne " *************************************\n"
	        else
			# xvid: bitrate setting is ignored during first pass
			nice -n $NICENESS mencoder $SOURCE_FILE -o $VIDEO_FILE \
				-vf pp=ci,crop=$VIDEO_CROP \
				-ovc xvid -xvidencopts pass=1:threads=$VIDEO_XVID_THREADS \
				-nosound -nosub
			nice -n $NICENESS mencoder $SOURCE_FILE -o $VIDEO_FILE \
				-vf pp=ci,crop=$VIDEO_CROP \
				-ovc xvid -xvidencopts pass=2:bitrate=$VIDEO_BITRATE:threads=$VIDEO_XVID_THREADS \
				-nosound -nosub
		fi
		;;
	esac


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

		MERGE_VIDEO="--aspect-ratio 0:$VIDEO_RATIO $VIDEO_FILE"
		MERGE_AUDIO="--language 0:$AUDIO_LANG --track-name 0:$AUDIO_NAME $AUDIO_FILE"

		# global merge command
		echo -ne "\n *************************************\n"
		echo " Final file merge:"
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
