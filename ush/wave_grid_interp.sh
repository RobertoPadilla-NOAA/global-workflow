#!/bin/bash
###############################################################################
#                                                                             #
# This script generates the interpolated data for the older grids             #
# in the MWW3 forecast model                                                  #
# It is run as a child scipt interactively by the postprocessor.              #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - This script generates it own sub-directory 'grint_*'.                     # 
# - See section 0.b for variables that need to be set.                        # 
# - The script is designed to generate interpolated files for a single step   #
#                                                                             #
#                                                             July 10, 2009   #
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

  cd $DATA

  grdID=$1  
  ymdh=$2
  dt=$3
  nst=$4
  postmsg "$jlogfile" "Making GRID Interpolation Files for $grdID."
  rm -rf grint_${grdID}_${ymdh}
  mkdir grint_${grdID}_${ymdh}
  err=$?
  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '******************************************************************************** '
    echo '*** FATAL ERROR : ERROR IN ww3_grid_interp (COULD NOT CREATE TEMP DIRECTORY) *** '
    echo '******************************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN ww3_grid_interp (COULD NOT CREATE TEMP DIRECTORY)" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_grid_interp (Could not create temp directory)"
    postmsg "$jlogfile" "$msg"
    err=1;export err;${errchk} || exit ${err}
  fi

  cd grint_${grdID}_${ymdh}

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!         Make GRID files        |'
  echo '+--------------------------------+'
  echo "   Model ID         : $WAV_MOD_TAG"
  [[ "$LOUD" = YES ]] && set -x

  if [ -z "$YMDH" ] || [ -z "$cycle" ] || [ -z "$EXECcode" ] || \
     [ -z "$COMOUT" ] || [ -z "$WAV_MOD_TAG" ] || [ -z "$SENDCOM" ] || \
     [ -z "$SENDDBN" ] || [ -z "$waveGRD" ]
  then
    set +x
    echo ' '
    echo '******************************************************'
    echo '*** EXPORTED VARIABLES IN wave_grid_interp NOT SET ***'
    echo '******************************************************'
    echo ' '
    echo "$YMDH $cycle $EXECcode $COMOUT $WAV_MOD_TAG $SENDCOM $SENDDBN $waveGRD"
    [[ "$LOUD" = YES ]] && set -x
    echo "EXPORTED VARIABLES IN wave_grid_interp NOT SET  " >> $wavelog
    msg="EXPORTED VARIABLES IN wave_grid_interp NOT SET"
    postmsg "$jlogfile" "$msg"
    err=2;export err;${errchk} || exit ${err}
  fi

# 0.c Links to files

  rm -f ../out_grd.$grdID
  
  if [ ! -f ../${grdID}_interp.inp.tmpl ]; then
    cp $FIXwave/${grdID}_interp.inp.tmpl ../.
  fi
  ln -sf ../${grdID}_interp.inp.tmpl . 

  for ID in $waveGRD
  do
    ln -sf ../out_grd.$ID .
  done

  for ID in $waveGRD $grdID 
  do
    ln -sf ../mod_def.$ID .
  done

# --------------------------------------------------------------------------- #
# 1.  Generate GRID file with all data
# 1.a Generate Input file

  time="`echo $ymdh | cut -c1-8` `echo $ymdh | cut -c9-10`0000"

  sed -e "s/TIME/$time/g" \
      -e "s/DT/$dt/g" \
      -e "s/NSTEPS/$nst/g" ${grdID}_interp.inp.tmpl > ww3_gint.inp

# Check if there is an interpolation weights file available

  wht_OK='no'
  if [ ! -f ${DATA}/WHTGRIDINT.bin.${grdID} ]; then
    if [ -f $FIXwave/WHTGRIDINT.bin.${grdID} ]
    then
      set +x
      echo ' '
      echo " Copying $FIXwave/WHTGRIDINT.bin.${grdID} "
      [[ "$LOUD" = YES ]] && set -x
      cp $FIXwave/WHTGRIDINT.bin.${grdID} ${DATA}
      wht_OK='yes'
    else
      set +x
      echo ' '
      echo " Not found: $FIXwave/WHTGRIDINT.bin.${grdID} "
      if [ "$err" != '0' ]
      then
        set +x
        echo ' '
        echo '************************************************************************ '
        echo '*** FATAL ERROR : Interpolation weights file WHTGRIDINT.bin.${grdID}   * '
        echo '***               NOT available in ${DATA} neither in ${FIXwave}       * '
        echo '************************************************************************ '
        echo ' '
        [[ "$LOUD" = YES ]] && set -x
        echo " Interpolation weights file WHTGRIDINT.bin.${grdID} NOT FOUND" >> $wavelog
        msg="FATAL ERROR : ERROR IN ww3_grid_interp, interpolation weights file NOT found"
        postmsg "$jlogfile" "$msg"
        err=3;export err;${errchk} || exit ${err}
      fi
    fi
  fi
# Check and link weights file
  if [ -f ${DATA}/WHTGRIDINT.bin.${grdID} ]
  then
    ln -s ${DATA}/WHTGRIDINT.bin.${grdID} ./WHTGRIDINT.bin
  fi

# 1.b Run interpolation code

  set +x
  echo "   Run ww3_gint
  echo "   Executing $EXECcode/ww3_gint
  [[ "$LOUD" = YES ]] && set -x

  $EXECcode/ww3_gint
  err=$?

# Write interpolation file to main TEMP dir area if not there yet
  if [ "wht_OK" = 'no' ]
  then
    cp -f ./WHTGRIDINT.bin ${DATA}/WHTGRIDINT.bin.${grdID}
    cp -f ./WHTGRIDINT.bin ${FIXwave}/WHTGRIDINT.bin.${grdID}
  fi
 
  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '******************************************************** '
    echo '*** FATAL ERROR : ERROR IN ww3_grid_interp             * '
    echo '***               moving WHTGRIDINT.bin to ${FIXwave}  * '
    echo '******************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "ERROR moving WHTGRIDINT.bin to ${FIXwave}" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_grid_interp moving WHTGRIDINT.bin"
    postmsg "$jlogfile" "$msg"
    err=4;export err;${errchk} || exit ${err}
  fi

# 1.b Clean up

  rm -f grid_interp.inp
  rm -f mod_def.*
  cp out_grd.$grdID ../out_grd.$grdID

# 1.c Save in /com

  if [ "$SENDCOM" = 'YES' ]
  then
    set +x
    echo "   Saving GRID file as $COMOUT/rundata/$WAV_MOD_TAG.out_grd.$grdID.$PDY$cyc"
    [[ "$LOUD" = YES ]] && set -x
    cp out_grd.$grdID $COMOUT/rundata/$WAV_MOD_TAG.out_grd.$grdID.$PDY$cyc

#    if [ "$SENDDBN" = 'YES' ]
#    then
#      set +x
#      echo "   Alerting GRID file as $COMOUT/rundata/$WAV_MOD_TAG.out_grd.$grdID.$PDY$cyc
#      [[ "$LOUD" = YES ]] && set -x

#
# PUT DBNET ALERT HERE ....
#

#    fi
  fi 

# --------------------------------------------------------------------------- #
# 2.  Clean up the directory

  set +x
  echo "   Removing work directory after success."
  [[ "$LOUD" = YES ]] && set -x

  cd ..
  mv -f grint_${grdID}_${ymdh} done.grint_${grdID}_${ymdh}

  set +x
  echo ' '
  echo "End of ww3_interp.sh at"
  date

# End of ww3_grid_interp.sh -------------------------------------------- #
