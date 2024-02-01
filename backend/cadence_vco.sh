#!/bin/sh
#************************************************************************CPY10*#
#*   Copyright Mentor Graphics Corporation 2005-2013                     CPY11*#
#*                    All Rights Reserved.                               CPY12*#
#*                                                                       CPY13*#
#*   THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION         CPY14*#
#*   WHICH IS THE PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS         CPY15*#
#*   LICENSORS AND IS SUBJECT TO LICENSE TERMS.                          CPY16*#
#************************************************************************CPY17*#
#
# Input environment variables:
#   USE_CALIBRE_VCO -- if set, forces output VCO to $VCO
#
# Usage:
#   calibre_vco
#     Output: VCO suitable for the current environment
#             If none, null string is returned with exit 1
#
#   calibre_vco -vcos
#     Output: List of all valid customer VCOs supported by Calibre
#
###############################################################################
PATH=/usr/bin:/bin
export PATH

if test "x$1" = x-vcos -a $# -eq 1
then
  # just echo the valid customer VCOs and exit
  echo 'aoi ira ixl'
elif test $# -ne 0
then
  echo 'ERROR: Invalid usage.' >&2
  echo 'Usage: calibre_vco [-vcos]' >&2
  echo
  exit 1
elif test -n "$USE_CALIBRE_VCO"
then
  echo $USE_CALIBRE_VCO
elif test `uname -s` = AIX
then
  major_rev=`uname -v`
  case "$major_rev" in
    5|6|7) echo ira ;;
    *)
      echo "ERROR: Invalid AIX major version '$major_rev'" >&2
      echo
      exit 1
      ;;
  esac
elif test `uname -s` = Linux
then
  if uname -m | grep '64$' >/dev/null 2>&1
  then
    # 64-bit OS is OK
    :
  else
    echo 'ERROR: 32-bit Linux operating system not supported.' >&2
    echo
    exit 1
  fi
  if test -r /etc/redhat-release
  then
    major_rev=`grep release /etc/redhat-release 2>/dev/null \
                 | sed -e 's/.*release *//' \
                 | sed -e 's/\..*//' \
                 | sed -e 's/ .*//'`
    case "$major_rev" in
      5)     echo ixl ;;
      [6-9]) echo aoi ;;
      *)
         echo "ERROR: Invalid Linux major version '$major_rev'" >&2
         echo
         exit 1
         ;;
      esac
  elif test -r /etc/SuSE-release
  then
    major_rev=`grep VERSION /etc/SuSE-release 2>/dev/null \
                 | sed -e 's/.*VERSION *= *//'`
    patch_level=`grep PATCHLEVEL /etc/SuSE-release 2>/dev/null \
                 | sed -e 's/.*PATCHLEVEL *= *//'`
    case "$major_rev" in
      11)
        if test -z "$patch_level" -o "$patch_level" -eq 1
        then
          echo ixl
        else
          echo aoi
        fi
        ;;
      12|13)  echo aoi ;;
      *)
        echo "ERROR: Invalid Linux major version '$major_rev'" >&2
        echo
        exit 1
        ;;
      esac
  elif test -r /etc/debian_version
  then
    echo aoi
  else
    echo 'ERROR: Unknown Linux operating system environment.' >&2
    echo
    exit 1
  fi
else
  echo 'ERROR: Unknown operating system environment.' >&2
  echo
  exit 1
fi
exit 0
