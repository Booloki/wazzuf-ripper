#! /bin/bash
# Wazzuf Ripper
# DVD/BD rip external tools download/install
# booloki@gmail.com

FUNCTIONS_PATH="wazzuf-ripper-functions"
FUNCTIONS_CHECK="$FUNCTIONS_PATH/wazzuf-functions-check"
EXTERNAL_TOOLS_PATH="wazzuf-external-tools"

source $FUNCTIONS_CHECK
mkdir -p $EXTERNAL_TOOLS_PATH
cd $EXTERNAL_TOOLS_PATH

# imdb-cli - no licence provided, but github so should be Open Source.
# https://github.com/bgr/imdb-cli
# + API http://www.imdbapi.com/
IMDBCLI_GIT="git://github.com/bgr/imdb-cli"
IMDBCLI_DIRECTORY="imdb-cli"
IMDBCLI_TOOL="../$EXTERNAL_TOOLS_PATH/$IMDBCLI_DIRECTORY/imdbtool.py"
echo -ne "\n*************************************\n"
echo -ne " imdb-cli can retrieve IMdb informations.\n"
echo -ne " Do you want to download/install imdb-cli ? (N/y)\n"
read answer
case $answer in
y* | Y* )
	# Check git
	if [ ! -x "/usr/bin/git" ]; then
		echo -ne "\n *************************************\n"
		echo -ne " Please install git !\n"
		echo -ne " Or manually download imdb-cli at https://github.com/bgr/imdb-cli/downloads\n"
		echo -ne " and extract archive to $EXTERNAL_TOOLS_PATH/$IMDBCLI_DIRECTORY/\n"
		echo -ne " Skip imdb-cli download/install.\n"
		echo -ne " *************************************\n" && sleep 1
	else
		git clone $IMDBCLI_GIT
	fi
	;;
* )
	echo -ne " Skip imdb-cli download/install.\n"
	;;
esac

# ccextractor - GPL 2.0
# http://ccextractor.sourceforge.net
CCEXTRACTOR_URL="http://sourceforge.net/projects/ccextractor/files/latest/download?source=files"
CCEXTRACTOR_FILE="download?source=files"
CCEXTRACTOR_DIRECTORY="ccextractor.0.63/linux"
CCEXTRACTOR_TOOL="../$EXTERNAL_TOOLS_PATH/$CCEXTRACTOR_DIRECTORY/ccextractor"
echo -ne "\n*************************************\n"
echo -ne " ccextractor can extract TS subtitles (CC): .srt files.\n"
echo -ne " Do you want to download/build ccextractor ? (N/y)\n"
read answer
case $answer in
y* | Y* )
	wget -nc $CCEXTRACTOR_URL
	check_7z
	7z x $CCEXTRACTOR_FILE
	# Check g++
	if [ ! -x "/usr/bin/g++" ]; then
		echo -ne "\n *************************************\n"
		echo -ne " Please install g++ !\n"
		echo -ne " Skip ccextractor build.\n"
		echo -ne " *************************************\n" && sleep 1
	else
		cd $CCEXTRACTOR_DIRECTORY
		./build
		cd ../../
	fi
	;;
* )
	echo -ne " Skip ccextractor download/build.\n"
	;;
esac

# tsMuxer (Freeware No longer developed)
# http://www.videohelp.com/tools/tsMuxeR
TSMUXER_URL="http://www.videohelp.com/download/tsMuxeR_1.10.6.tar.gz?r=dQFgXXDBWw"
TSMUXER_FILE="tsMuxeR_1.10.6.tar.gz?r=dQFgXXDBWw"
TSMUXER_DIRECTORY="tsmuxer"
TSMUXER_TOOL="../$EXTERNAL_TOOLS_PATH/$TSMUXER_DIRECTORY/tsMuxeR"
echo -ne "\n*************************************\n"
echo -ne " tsMuxer can extract/demux BD subtitle (PGS): .sup files.\n"
echo -ne " Do you want to download/install tsMuxer ? (N/y)\n"
read answer
case $answer in
y* | Y* )
	wget -nc $TSMUXER_URL
	mkdir -p $TSMUXER_DIRECTORY
	tar xvzf $TSMUXER_FILE -C $TSMUXER_DIRECTORY
	;;
* )
	echo -ne " Skip tsMuxer download/install.\n"
	;;
esac

exit 0