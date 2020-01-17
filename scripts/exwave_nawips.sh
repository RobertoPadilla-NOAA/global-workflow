#!/bin/bash
###############################################################################
#                                                                             #
# This script is the postprocessor for the Global-workflow  WW3 wave model.   #
#  it sets some shell script variables for export to child scripts and copies #
# some generally used files to the work directory. After this the actual      #
# postprocessing is performed by the following child scripts :                #
#                                                                             #
#  ???.sh              : generates GRIB2 files.                               #
#  ???.sh              : generates spectral data files for output             #
#                             locations.                                      #
#                                                                             #
# Remarks :                                                                   #
# - ??? above scripts are (mostly) run using mpiserial or cfp.                #
#   ??? script runs in its own directory created in DATA. If all is well      #
#   ...............                                                           #
#                                                                             #
# Origination  : Mar 2000                                                     #
#                                                                             #
# Update log                                                                  #
#  May2008 S Lilly: - add logic to make sure that all of the "                #
#                     data produced from the restricted ECMWF"                #
#                     data on the CCS is properly protected."                 #
# Jan2020 Rpadilla, JHAlves                                                   #
#                   - Merging wave scripts to global workflow                 #
#                                                                             #
###############################################################################
# --------------------------------------------------------------------------- #
#XXX Do we need the following lines?
###################################################################
echo "----------------------------------------------------"
echo "exnawips - convert NCEP GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"
echo "History: Mar 2000 - First implementation of this new script."
echo "S Lilly: May 2008 - add logic to make sure that all of the "
echo "                    data produced from the restricted ECMWF"
echo "                    data on the CCS is properly protected."
echo "D Stokes: Oct 2011 - specific version for wave_multi_1."
echo "                    Use grib2 for akw, wna and enp."
#####################################################################

set -xa

if [ $NET = wave ]
then
  if [[ "$job" =~ "wave_enp_gempak" ]] || [[ "$job" =~ "wave_wna_gempak" ]] || [[ "$job" =~ "wave_alaska_gempak" ]] || [[ "$job" =~ "wave_multi_2_gempak" ]]
  then
    export RUN=$1
    export model=$2
    export DATA=$3
  fi
  RUN3=`echo $RUN | cut -c1-3`
  RUN4=`echo $RUN | cut -c1-4`
fi

cd $DATA

NAGRIB=nagrib_nc

entry=`grep "^$RUN " $NAGRIB_TABLE | awk 'index($1,"#") != 1 {print $0}'`

if [ "$entry" != "" ] ; then
  cpyfil=`echo $entry  | awk 'BEGIN {FS="|"} {print $2}'`
  garea=`echo $entry   | awk 'BEGIN {FS="|"} {print $3}'`
  gbtbls=`echo $entry  | awk 'BEGIN {FS="|"} {print $4}'`
  maxgrd=`echo $entry  | awk 'BEGIN {FS="|"} {print $5}'`
  kxky=`echo $entry    | awk 'BEGIN {FS="|"} {print $6}'`
  grdarea=`echo $entry | awk 'BEGIN {FS="|"} {print $7}'`
  proj=`echo $entry    | awk 'BEGIN {FS="|"} {print $8}'`
  output=`echo $entry  | awk 'BEGIN {FS="|"} {print $9}'`
else
  cpyfil=gds
  garea=dset
  gbtbls=
  maxgrd=4999
  kxky=
  grdarea=
  proj=
  output=T
fi  
pdsext=no

#

maxtries=180
fhcnt=$fstart
while [ $fhcnt -le $fend ] ; do
  if [ $fhcnt -ge 100 ] ; then
    typeset -Z3 fhr
  else
    typeset -Z2 fhr
  fi
  fhr=$fhcnt

  fhr3=$fhcnt
  typeset -Z3 fhr3
  GRIBIN=$COMIN/${model}.${cycle}.${GRIB}${fhr}${EXT}
  GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}

  case $RUN in
   gfswavglo10m) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gfswavaoc9km) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gfswavant9km) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   nww3 | nah | nph)  
         GRIBIN=$COMIN/${model}.${cycle}.${GRIB}
         GEMGRD=${RUN}_${PDY}${cyc} ;;
    akw | wna | enp)  
         GRIBIN=$COMIN/${model}.${cycle}.${GRIB}.grib2
         GEMGRD=${RUN}_${PDY}${cyc} 
         NAGRIB=nagrib2 ;;
   mww3) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3ak10m) GRIBIN=$COMIN/multi_1.ak_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3ak4m) GRIBIN=$COMIN/multi_1.ak_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wna10m) GRIBIN=$COMIN/multi_1.at_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wna4m) GRIBIN=$COMIN/multi_1.at_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wc10m) GRIBIN=$COMIN/multi_1.wc_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wc4m) GRIBIN=$COMIN/multi_1.wc_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3enp10m) GRIBIN=$COMIN/multi_1.ep_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${RUN}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
  esac

  if [ $RUN = "nww3" -o $RUN = "nah" -o $RUN = "nph" ] ; then
    GRIBIN_chk=$COMIN/${model}.${cycle}.${GRIB}done 
  elif [ $RUN = "akw" -o $RUN = "wna" -o $RUN = "enp" ] ; then
    GRIBIN_chk=$GRIBIN.idx
  elif [ $RUN4 = "mww3" ]; then
    GRIBIN_chk=$GRIBIN.idx
  else
    GRIBIN_chk=$GRIBIN
  fi

  icnt=1
  while [ $icnt -lt 1000 ]
  do
    if [ -r $GRIBIN_chk ] ; then
#    if [ -s $GRIBIN_chk ] ; then
      break
    else
      let "icnt=icnt+1"
      sleep 20
    fi
    if [ $icnt -ge $maxtries ]
    then
      msg="ABORTING after 1 hour of waiting for F$fhr to end."
      err_exit $msg
    fi
  done

  cp $GRIBIN grib$fhr

  pgm="$NAGRIB for F$fhr $model"
  startmsg

  $NAGRIB << EOF
   GBFILE   = grib$fhr
   INDXFL   = 
   GDOUTF   = $GEMGRD
   PROJ     = $proj
   GRDAREA  = $grdarea
   KXKY     = $kxky
   MAXGRD   = $maxgrd
   CPYFIL   = $cpyfil
   GAREA    = $garea
   OUTPUT   = $output
   GBTBLS   = $gbtbls
   GBDIAG   = 
   PDSEXT   = $pdsext
  l
  r
EOF
  export err=$?;err_chk

  #####################################################
  # GEMPAK DOES NOT ALWAYS HAVE A NON ZERO RETURN CODE
  # WHEN IT CAN NOT PRODUCE THE DESIRED GRID.  CHECK
  # FOR THIS CASE HERE.
  #####################################################
  if [ $model != "ukmet_early" ] ; then
    ls -l $GEMGRD
    export err=$?;export pgm="GEMPAK CHECK FILE for $GEMGRD";err_chk
  fi

  if [ "$NAGRIB" = "nagrib2" ] ; then
    gpend
  fi

  #
  if [ $SENDCOM = "YES" ] ; then
     if [ $RUN = "ecmwf_hr" -o $RUN = "ecmwf_wave" ] ; then
       chgrp rstprod $GEMGRD
       chmod 750 $GEMGRD
     fi
     mv $GEMGRD $COMOUT/$GEMGRD
     if [ $SENDDBN = "YES" ] ; then
         $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
           $COMOUT/$GEMGRD
     else
       echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} #####"
     fi
  fi

  let fhcnt=fhcnt+finc
done

#####################################################################
# GOOD RUN
set +x
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON THE IBM"
set -x
#####################################################################


############################### END OF SCRIPT #######################
