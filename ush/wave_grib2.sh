#!/bin/bash
###############################################################################
#                                                                             #
# This script generates the GRIB2 file for the MWW3 forecast model            #
# It is run as a child scipt interactively by the postprocessor.              #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - This script generates it own sub-directory 'grib_*'.                      # 
# - See section 0.b for variables that need to be set.                        # 
#                                                                             #
#                                                                July, 2007   #
# Update log                                                                  #
# Nov2019 JHAlves - Merging wave scripts to global workflow                   #
# Jan2020 RPadilla, JHAlves  - Adding error checking                          #
#                                                                             #
###############################################################################

#
# ... Define directories
#
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

  cd $GRIBDATA
#  postmsg "$jlogfile" "Making GRIB2 Files."   # commented to reduce unnecessary output to jlogfile

  grdID=$1 
  gribDIR=${grdID}_grib 
  rm -rfd ${gribDIR}
  mkdir ${gribDIR}
  err=$?
  if [ $err != 0 ]
  then
    set +x
    echo ' '
    echo '********************************************************************* **** '
    echo '*** FATAL ERROR : ERROR IN ww3_grib2 (COULD NOT CREATE TEMP DIRECTORY) *** '
    echo '************************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN ww3_grib2 (COULD NOT CREATE TEMP DIRECTORY)" >> $wavelog
    msg= "FATAL ERROR : ERROR IN ww3_grib2 (Could not create temp directory)"
    postmsg "$jlogfile" "$msg"
    err=1;export err;${errchk} || exit ${err}
  fi

  cd ${gribDIR}

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  dtgrib=$2
  ngrib=$3
  GRIDNR=$4
  MODNR=$5
  gribflags=$6

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!         Make GRIB files        |'
  echo '+--------------------------------+'
  echo "   Model ID         : $WAV_MOD_TAG"
  [[ "$LOUD" = YES ]] && set -x

  if [ -z "$YMDH" ] || [ -z "$cycle" ] || [ -z "$EXECwave" ] || [ -z "$EXECcode" ] || \
     [ -z "$COMOUT" ] || [ -z "$WAV_MOD_TAG" ] || [ -z "$SENDCOM" ] || \
     [ -z "$dtgrib" ] || [ -z "$ngrib" ] || [ -z "$gribflags" ] || \
     [ -z "$GRIDNR" ] || [ -z "$MODNR" ] || [ -z "$SENDDBN" ]
  then
    set +x
    echo ' '
    echo '******************************************************************'
    echo '*** EXPORTED VARIABLES IN postprocessor NOT SET in wave_grib2 *** '
    echo '***************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "EXPORTED VARIABLES IN postprocessor NOT SET in wave_grib2  " >> $wavelog
    msg="EXPORTED VARIABLES IN postprocessor NOT SET"
    postmsg "$jlogfile" "msg"
    err=2;export err;${errchk} || exit ${err}
  fi

# 0.c Starting time for output

  ymdh=$YMDH
  tstart="`echo $ymdh | cut -c1-8` `echo $ymdh | cut -c9-10`0000"

  set +x
  echo "   Starting time    : $tstart"
  echo "   Time step        : $dtgrib"
  echo "   Number of times  : $ngrib"
  echo "   GRIB field flags : $gribflags"
  echo ' '
  [[ "$LOUD" = YES ]] && set -x

# 0.e Links to working directory

  ln -s ../mod_def.$grdID mod_def.ww3
  ln -s ../out_grd.$grdID out_grd.ww3 

# --------------------------------------------------------------------------- #
# 1.  Generate GRIB file with all data
# 1.a Generate input file for ww3_grib2
#     Template copied in mother script ...

  set +x
  echo "   Generate input file for ww3_grib2"
  [[ "$LOUD" = YES ]] && set -x

  sed -e "s/TIME/$tstart/g" \
      -e "s/DT/$dtgrib/g" \
      -e "s/NT/$ngrib/g" \
      -e "s/GRIDNR/$GRIDNR/g" \
      -e "s/MODNR/$MODNR/g" \
      -e "s/FLAGS/$gribflags/g" \
                               ../ww3_grib2.inp.tmpl > ww3_grib.inp

# 1.b Run GRIB packing program

  set +x
  echo "   Run ww3_grib2"
  echo "   Executing $EXECcode/ww3_grib"
  [[ "$LOUD" = YES ]] && set -x

  ln -sf ../$WAV_MOD_TAG.$grdID.${cycle}.grib2 gribfile
  $EXECcode/ww3_grib
  err=$?

  if [ $err != 0 ]
  then
    set +x
    echo ' '
    echo '******************************************************************* '
    echo '*** FATAL ERROR : ERROR IN ww3_grib2 running $EXECcode/ww3_grib *** '
    echo '******************************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN ww3_grib2 running $EXECcode/ww3_grib" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_grib2 running $EXECcode/ww3_grib"
    postmsg "$jlogfile" "$msg"
    err=3;export err;${errchk} || exit ${err}
  fi

# 1.c Clean up

  rm -f ww3_grib.inp
  rm -f mod_def.ww3
  rm -f out_grd.ww3

# 1.e Save in /com

  if [ "$SENDCOM" = 'YES' ]
  then
    set +x
    echo "   Saving GRIB file as $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2"
    [[ "$LOUD" = YES ]] && set -x
    cp -f ${DATA}/$WAV_MOD_TAG.$grdID.$cycle.grib2 $COMOUT/gridded/
    $WGRIB2 -s $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2 > $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2.idx
    
    if [ ! -f $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2 ]
    then
      set +x
      echo ' '
      echo '***************************************************************** '
      echo '*** FATAL ERROR : ERROR IN ww3_grib2 moving grib2 file to  com*** '
      echo '***************************************************************** '
      echo ' '
      echo " Error in moving grib file $WAV_MOD_TAG.$grdID.$cycle.grib2 to com"
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      echo "RROR IN ww3_grib2 moving grib2 file to  com " >> $wavelog
      msg= "Error in moving grib file $WAV_MOD_TAG.$grdID.$cycle.grib2 to com"
      postmsg "$jlogfile" "$msg"
      err=4;export err;${errchk} || exit ${err}
    fi
    if [ ! -f $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2.idx ]
    then
      set +x
      echo ' '
      echo '********************************************************************** '
      echo '*** FATAL ERROR : ERROR IN ww3_grib2 moving the INDEX FILE to  com *** '
      echo '********************************************************************** '
      echo ' '
      echo " Error in moving grib file $WAV_MOD_TAG.$grdID.$cycle.grib2.idx to com"
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      echo " ERROR IN ww3_grib2 moving the INDEX FILE to  com" >> $wavelog
      msg="FATAL ERROR : ERROR IN creating ww3_grib2 index"
      postmsg "$jlogfile" "$msg"
      err=5;export err;${errchk} || exit ${err}
    fi

    if [ "$SENDDBN" = 'YES' ]
    then
      set +x
      echo "   Alerting GRIB file as $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2"
      echo "   Alerting GRIB index file as $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2.idx"
      [[ "$LOUD" = YES ]] && set -x
      $DBNROOT/bin/dbn_alert MODEL WAVE_GRIB_GB2 $job $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2
      $DBNROOT/bin/dbn_alert MODEL WAVE_GRIB_GB2_WIDX $job $COMOUT/gridded/$WAV_MOD_TAG.$grdID.$cycle.grib2.idx
    fi
  fi 

 
# --------------------------------------------------------------------------- #
# 3.  Clean up the directory

  set +x
  echo "   Removing work directory after success."
  [[ "$LOUD" = YES ]] && set -x

  cd ..
  mv -f ${gribDIR} done.${gribDIR}

  set +x
  echo ' '
  echo "End of ww3_grib2.sh at"
  date
  [[ "$LOUD" = YES ]] && set -x

# End of ww3_grib2.sh -------------------------------------------------- #
