#!/bin/sh
###############################################################################
#                                                                             #
# This script preprocesses ice fields for the ocean wave models.              #
# It is run as a child scipt by the corresponding preprocessig script.        #
#                                                                             #
# Remarks :                                                                   #
# - This script runs in the work directory designated in the mother script in #
#   which it generates its own sub-directory 'ice'.                           #
# - Because this script is not essential for the running for the wave model   #
#   (as long as it runs every now and then) the error exit codes are set to   #
#   0. The main program script will then not find the file ice.ww3 and send   #
#   a message to the wave.log file.                                           #
# - See section 0.b for variables that need to be set.                        #
#                                                                             #
#  Update record :                                                            #
#                                                                             #
# - Origination:                                               01-Mar-2007    #
#                                                                             #
# Update log                                                                  #
# Nov2019 JHAlves - Merging wave scripts to global workflow                   #
# Jan2020 RPadilla, HAlves  - Adding error checking                           #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 0.  Preparations
# 0.a Basic modes of operation

  cd $DATA
  seton='-xa'
  setoff='+xa'
  set $seton

  rm -rf ice
  mkdir ice
  err=$?
  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '********************************************************************** '
    echo '*** FATAL ERROR : ERROR IN wave_prnc_ice COULD NOT CREATE  ice Dir *** '
    echo '********************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN wave_prnc_ice COULD NOT CREATE  rtofs_${fext}${fhr} Dir" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_outp_spec (Could not create temp directory)"
    postmsg "$jlogfile" "$msg"
    err=1;export err;${errchk} || exit ${err}
  fi

  cd ice
  ln -s ${DATA}/postmsg .

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  set $setoff
  echo ' '
  echo '+--------------------------------+'
  echo '!         Make ice fields        |'
  echo '+--------------------------------+'
  echo "   Model TAG       : $WAV_MOD_TAG"
  echo "   Model ID        : $WAV_MOD_ID"
  echo "   Ice grid ID     : $iceID"
  echo ' '
  set $seton
  postmsg "$jlogfile" "Making ice fields."

  if [ -z "$YMDH" ] || [ -z "$cycle" ] || \
     [ -z "$COMOUT" ] || [ -z "$FIXwave" ] || [ -z "$EXECcode" ] || \
     [ -z "$WAV_MOD_TAG" ] || [ -z "$iceID" ] || [ -z "$SENDCOM" ] || \
     [ -z "$COMINice" ] || [ -z "$WAV_MOD_ID" ]
  then
    set $setoff
    echo ' '
    echo '**************************************************'
    echo '*** EXPORTED VARIABLES IN wave_prnc_ice NOT SET ***'
    echo '**************************************************'
    echo ' '
    set $seton
    echo " EXPORTED VARIABLES IN wave_prnc_ice NOT SET " >> $wavelog
    msg="NON-FATAL ERROR - EXPORTED VARIABLES IN wave_prnc_ice NOT SET"
    postmsg "$jlogfile" "$msg"
    err=2;export err;${errchk} || exit ${err}
  fi

# 0.c Links to working directory

  ln -s ${DATA}/mod_def.$iceID mod_def.ww3

# --------------------------------------------------------------------------- #
# 1.  Get the necessary files
# 1.a Copy the ice data file

  if [ "$cycle" = 't00z' ]  || [ "$cycle" = 't06z' ]
  then
    timeID="`$NDATE -24 $YMDH | cut -c3-8`00"
    YMD="`$NDATE -24 $YMDH | cut -c1-8`"
  else
    timeID="`echo $YMDH | cut -c 3-8`00"
    YMD="`echo $YMDH | cut -c 1-8`"
  fi

  file=$COMINice/sice.$YMD/seaice.t00z.5min.grb.grib2

  if [ -f $file ]
  then
    cp $file ice.grib
  else



  fi

  if [ -f ice.grib ]
  then
    set $setoff
    echo "   ice.grib copied ($file)."
    set $seton
  else
    set $setoff
    echo ' '
    echo '************************************** '
    echo "*** FATAL ERROR: NO ICE FILE $file ***  "
    echo '************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " FATAL ERROR: NO ICE FILE $file" >> $wavelog
    msg="FATAL ERROR : ERROR NO ICE FILE (GFS GRIB) "
    postmsg "$jlogfile" 
    err=3;export err;${errchk} || exit ${err}
  fi

# --------------------------------------------------------------------------- #
# 2.  Process the GRIB packed ice file
# 2.a Make an index file

  set $setoff
  echo ' '
  echo '   Making GRIB index file ...'
  set $seton

  $WGRIB2 ice.grib > ice.index

# 2.b Check valid time in index file

  set $setoff
  echo "   Time ID of ice field : $timeID"
  set $seton

  if [ -z "`grep $timeID ice.index`" ]
  then
    set $setoff
    echo ' '
    echo '********************************************** '
    echo '*** ERROR : ICE FIELD WITH UNEXPECTED DATE *** '
    echo '********************************************** '
    echo ' '
    set $seton
    echo "ERROR : ICE FIELD WITH UNEXPECTED DATE  " >> $wavelog
    msg="NON-FATAL ERROR - ICE FIELD WITH UNEXPECTED DATE"
    postmsg "$jlogfile" "$msg"
    err=4;export err;${errchk} || exit ${err}
  fi

# 2.c Unpack data

  set $setoff
  echo '   Extracting data from ice.grib ...'
  set $seton

  grep $timeID ice.index | \
           $WGRIB2 ice.grib -netcdf icean_5m.nc 2>&1 > wgrib.out
           #$WGRIB ice.grib -i -text -o ice.raw 2>&1 > wgrib.out

  err=$?

  if [ "$err" != '0' ]
  then
    cat wgrib.out
    set $setoff
    echo ' '
    echo '**************************************** '
    echo '*** ERROR IN UNPACKING GRIB ICE FILE *** '
    echo '**************************************** '
    echo ' '
    set $seton 
    echo "ERROR IN UNPACKING GRIB ICE FILE " >> $wavelog
    msg="ERROR IN UNPACKING GRIB ICE FILE."
    postmsg "$jlogfile" "$msg"
    err=5;export err;${errchk} || exit ${err}
  fi

  rm -f wgrib.out
  rm -f ice.grib 
  rm -f ice.index


# 2.d Run through preprocessor wave_prep

  set $setoff
  echo '   Run through preprocessor ...'
  echo ' '
  set $seton

  cp -f ${DATA}/ww3_prnc.ice.$iceID.inp.tmpl ww3_prnc.inp

  $EXECcode/ww3_prnc > wave_prnc.out
  err=$?

  if [ "$err" != '0' ]
  then
    cat wave_prep.out
    set $setoff
    echo ' '
    echo '*************************************** '
    echo '*** ERROR IN $EXECcode/ww3_prnc_ice *** '
    echo '*************************************** '
    echo ' '
    set $seton
    echo "ERROR IN $EXECcode/ww3_prnc_ice " >> $wavelog
    msg="ERROR RUNNING $EXECcode/ww3_prnc"
    postmsg "$jlogfile" "$msg"
    err=6;export err;${errchk} || exit ${err}
  fi

  rm -f wave_prep.out ww3_prep.inp ice.raw mod_def.ww3

# --------------------------------------------------------------------------- #
# 3.  Save the ice file
#
# Ice file name will have ensemble member number if WW3ATMIENS=T
# and only WAV_MOD_ID if WW3ATMIENS=F
#
  if [ "${WW3ATMIENS}" = "T" ]
  then 
    icefile=${WAV_MOD_TAG}.${iceID}.$cycle.ice
  elif [ "${WW3ATMIENS}" = "F" ]
  then 
    icefile=${WAV_MOD_ID}.${iceID}.$cycle.ice
  fi
 
  set $setoff
  echo "   Saving ice.ww3 as $COMOUT/rundata/${icefile}"
  set $seton
  if [ ! -f ice.ww3 ]
  then
    set +x
    echo ' '
    cat waveprep.out
    echo ' '
    echo '****************************************'
    echo '*** FATAL ERROR : ice.ww3 NOT FOUND ***'
    echo '****************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " FATAL ERROR : ice.ww3 NOT FOUND" >> $wavelog
    msg="ABNORMAL EXIT: FILE ice.ww3 MISSING"
    postmsg "$jlogfile" "$msg"
    err=7;export err;${errchk} || exit ${err}
  fi

  cp ice.ww3 $COMOUT/rundata/${icefile}
  rm -f ice.ww3

# --------------------------------------------------------------------------- #
# 4.  Clean up the directory

  set $setoff
  echo "   Removing work directory after success."
  set $seton

  cd ..
  rm -rf ice

  set $setoff
  echo ' '
  echo 'End of waveice.sh at'
  date

# End of waveice.sh --------------------------------------------------------- #
