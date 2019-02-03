#! /bin/bash

# Batch Convert Script by StevenTrux https://github.com/steventrux/castize
# The Purpose of this Script is to batch convert any video file to mp4 or mkv format for chromecast compatibility
# this script only convert necessary tracks if the video is already
# in H.264 format it won't convert it saving your time!

# Variable used:
# outmode should be mp4 or mkv
# sourcedir is the directory where to be converted videos are
# indir is the directory where converted video will be created

# usage:
#########################
# cast.sh mp4 /home/user/divx /home/user/chromecastvideos
# or
# cast.sh mkv /home/user/divx /home/user/chromecastvideos
# ./Chromecast-conversion.sh mkv . .
#########################

VCODEC="h264_omx"
V_CODEC_ARG="-vsync 0 -keyint_min 0 -g 100 -b:v 1000k -profile:v high -level 4.1"

#VCODEC="libx264"
#V_CODEC_ARG="-vsync 0 -profile:v main -level 3.1 -qmax 22 -qmin 20 -x264opts no-cabac:ref=2"

#audio codec args
A_CODEC_ARG="-ab 192k -ac 2 -absf aac_adtstoasc"

#work only with custom compiled libfdk_aac
FFMPEG="/usr/local/bin/ffmpeg"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

# working mode
outmode=$1
# check output mode
if [[ $outmode ]]; then
if [ $outmode = "mp4" ] || [ $outmode = "mkv" ]
        then
        echo "WORKING MODE $outmode"
        else
        echo "$outmode is NOT a Correct target format. You need to set an output format! like cast.sh mp4 xxxx or cast.sh mkv xxxx"
        exit
fi
else
echo "Working mode is missing. You should set a correct target format like mp4 or mkv"
echo "./Chromecast-conversion.sh mkv . ."
exit
fi

# Source dir
sourcedir=$2
if [[ $sourcedir ]]; then
     echo "Using $sourcedir as Input Folder"
        else
         echo "Error: Check if you have set an input folder"
         exit
fi

# Target dir
indir=$3
if [[ $indir ]]; then
if mkdir -p $indir/castable
        then
         echo "Using $indir/castable as Output Folder"
        else
         echo "Error: Check if you have the rights to write in $indir"
         exit
fi
        else
         echo "Error: Check if you have set an output folder"
         exit
fi

# set format
if [ $outmode = mp4 ]
        then
         outformat=mp4
        else
         outformat=matroska
fi

# Check FFMPEG Installation
if ffmpeg -formats > /dev/null 2>&1
        then
         ffversion=`ffmpeg -version 2> /dev/null | grep ffmpeg | sed -n 's/ffmpeg\s//p'`
         echo "Your ffmpeg verson is $ffversion"
        else
         echo "ERROR: You need ffmpeg installed with ${VCODEC} and libfdk_aac encoder"
         exit
fi

if ffmpeg -formats 2> /dev/null | grep "E mp4" > /dev/null
        then
         echo "Check mp4 container format ... OK"
        else
         echo "Check mp4 container format ... NOK"
         exit
fi

if ffmpeg -formats 2> /dev/null | grep "E matroska" > /dev/null
        then
         echo "Check mkv container format ... OK"
        else
         echo "Check mkv container format ... NOK"
         exit
fi

if ffmpeg -codecs 2> /dev/null | grep "libfdk_aac" > /dev/null
        then
         echo "Check AAC Audio Encoder ... OK"
        else
         echo "Check AAC Audio Encoder ... NOK"
         exit
fi

if ffmpeg -codecs 2> /dev/null | grep ${VCODEC} > /dev/null
        then
         echo "Check x264 the free H.264 Video Encoder ... OK"
        else
         echo "Check x264 the free H.264 Video Encoder ... NOK"
         exit
fi

echo "Your FFMpeg is OK Entering File Processing" ; echo ""

################################################################
cd "$sourcedir"
#for filelist in `ls`
find . -type f -printf '%P\n' | while read filelist;
do
#echo $filelist
#continue
        if [ -f "$indir/castable/${filelist%.*}.$outmode" ]
            then
            echo "File $indir/castable/${filelist%.*}.$outmode exists!"
            echo "Not need convert file ${filelist}" ; echo ""
            continue
        fi

        if ffmpeg -i "$filelist" 2>&1 | grep 'Invalid data found'               #check if it's video file
           then
           echo "ERROR File $filelist is NOT A VIDEO FILE can be converted!"
           continue

        fi

        if ffmpeg -i "$filelist" 2>&1 | grep Video: | grep h264         #check video codec
           then
            vcodec=copy
            V_CODEC_ARG=""
           else
            vcodec=${VCODEC}
        fi

        if ffmpeg -i "$filelist" 2>&1 | grep Video: | grep "High 10"    #10 bit H.264 can't be played by Hardware.
           then
            vcodec=${VCODEC}
        fi

        if ffmpeg -i "$filelist" 2>&1 | grep Audio: | grep aac || ffmpeg -i "$filelist" 2>&1 | grep Audio: | grep mp3  #check audio codec
           then
            acodec=copy; A_CODEC_ARG=""
           else
            acodec=libfdk_aac
        fi

        echo "${red}Converting $filelist"
        echo "Video codec: $vcodec"
        echo "Audio codec: $acodec"
        echo "Container: $outformat${reset}"

# using ffmpeg for real converting
        echo "ffmpeg -threads 16 -i  $filelist  -y -f $outformat -acodec $acodec ${A_CODEC_ARG} -async 1 -vcodec $vcodec ${V_CODEC_ARG}  $indir/castable/${filelist%.*}.$outmode"
           ${FFMPEG} -threads 16 -i "$filelist" -y -f $outformat -acodec $acodec ${A_CODEC_ARG} -async 1 -vcodec $vcodec ${V_CODEC_ARG} "$indir/castable/${filelist%.*}.$outmode" < /dev/null

done
        echo ALL Processed!

###################
echo "DONE, your video files are chromecast ready"
exit
