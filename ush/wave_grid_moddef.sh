#!/bin/bash
###############################################################################
#                                                                             #
# This script creates the mod_def file for the grid.                          #
#                                                                             #
# Remarks :                                                                   #
# - Shell script variables controling time, directories etc. are set in the   #
#   mother script.                                                            #
# - This script runs in the work directory designated in the mother script.   #
# - Script is run in a sub directory that is then removed at the end          #
# - See section 0.c for variables that need to be set.                        #
#                                                                             #
#                                                            April 08, 2011   #
# Update log                                                                  #
# Nov2019 JHAlves - Merging wave scripts to global workflow                   #
# Jan2020 RPadilla, JHAlves  - Adding error checking                          #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 0.  Preparations
# 0.a Basic modes of operation

  # set execution trace prompt.  ${0##*/} adds the script's basename
  PS4=" \${SECONDS} ${0##*/} L\${LINENO} + "
  set -x

  # Use LOUD variable to turn on/off trace.  Defaults to YES (on).
  export LOUD=${LOUD:-YES}; [[ $LOUD = yes ]] && export LOUD=YES
  [[ "$LOUD" != YES ]] && set +x
  msg="Generating mod_def file"
  postmsg "$jlogfile" "$msg"

  mkdir -p moddef_${1}
  err=$?
  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************************************** '
    echo '*** FATAL ERROR : In ww3_grid_moddef (COULD NOT CREATE TEMP DIRECTORY) *** '
    echo '************************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN ww3_grid_moddef(COULD NOT CREATE TEMP DIRECTORY)" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_grid_interp (Could not create temp directory)"
    postmsg "$jlogfile" "$msg"
    err=1;export err;${errchk} || exit ${err}
  fi

  cd moddef_${1}

  grdID=$1

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!     Generate moddef file       |'
  echo '+--------------------------------+'
  echo "   Grid            : $1"
  echo ' '
  [[ "$LOUD" = YES ]] && set -x

# 0.b Check if grid set

  if [ "$#" -lt '1' ]
  then
    set +x
    echo ' '
    echo '*************************************** '
    echo '*** Grid in ww3_mod_def.sh NOT SET  *** '
    echo '*************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " Grid in ww3_mod_def.sh NOT SET" >> $wavelog
    msg="GRID IN ww3_mod_def.sh NOT SET"
    postmsg "$jlogfile" "$msg"
    err=2;export err;${errchk} || exit ${err}
  else
    grdID=$1
  fi

# 0.c Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  if [ -z "$grdID" ] || [ -z "$EXECcode" ] || [ -z "$wave_sys_ver" ]
  then
    set +x
    echo ' '
    echo '****************************************************'
    echo '*** EXPORTED VARIABLES IN ww3_mod_def.sh NOT SET ***'
    echo '****************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "EXPORTED VARIABLES IN ww3_mod_def.sh NOT SET " >> $wavelog
    postmsg "$jlogfile" "EXPORTED VARIABLES IN ww3_mod_def.sh NOT SET"
    err=3;export err;${errchk} || exit ${err}
  fi

# --------------------------------------------------------------------------- #
# 2.  Create mod_def file 

  set +x
  echo ' '
  echo '   Creating mod_def file ...'
  echo "   Executing $EXECcode/ww3_grid"
  echo ' '
  [[ "$LOUD" = YES ]] && set -x
 
  rm -f ww3_grid.inp 
  ln -sf ../ww3_grid.inp.$grdID ww3_grid.inp
 
  $EXECcode/ww3_grid
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '******************************************** '
    echo '*** FATAL ERROR : ERROR running ww3_grid *** '
    echo '******************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "FATAL ERROR : running ww3_grid " >> $wavelog
    msg="FATAL ERROR : running ww3_grid"
    postmsg "$jlogfile" "$msg"
    err=4;export err;${errchk} || exit ${err}
  fi
 
  if [ -f mod_def.ww3 ]
  then
    cp mod_def.ww3 $COMOUT/rundata/${WAV_MOD_ID}.mod_def.${grdID}
    mv mod_def.ww3 ../mod_def.$grdID
  else
    set +x
    echo ' '
    echo '******************************************** '
    echo '*** FATAL ERROR : MOD DEF FILE NOT FOUND *** '
    echo '******************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "FATAL ERROR : MOD DEF FILE NOT FOUND " >> $wavelog
    msg="FATAL ERROR : Mod def File creation FAILED"
    postmsg "$jlogfile" "$msg" 
    err=5;export err;${errchk} || exit ${err}
  fi

# --------------------------------------------------------------------------- #
# 3.  Clean up

  cd ..
  #rm -rf moddef_$grdID

  set +x
  echo ' '
  echo 'End of ww3_mod_def.sh at'
  date

# End of ww3_mod_def.sh ------------------------------------------------- #
