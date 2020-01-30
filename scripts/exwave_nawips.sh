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
# - ??? above scripts are (mostly) grdID using mpiserial or cfp.              #
#   ??? script grdIDs in its own directory created in DATA. If all is well    #
#   ...............                                                           #
#                                                                             #
# Origination  : Mar 2000                                                     #
#                                                                             #
# Update log                                                                  #
#  May2008 S Lilly:  - add logic to make sure that all of the "               #
#                     data produced from the restricted ECMWF"                #
#                     data on the CCS is properly protected."                 #
# Oct 2011 D Stokes: - specific version for wave_multi_1."                    #
#                     Use grib2 for akw, wna and enp."                        #
# Jan2020 Rpadilla,  JHAlves                                                  #
#                    - Merging wave scripts to global workflow                #
#                                                                             #
###############################################################################
#

echo "----------------------------------------------------"
echo "exnawips - convert NCEP GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"


set +xa
echo "job: $job"
echo $0 $1 $2 $3
export grdID=$1 
#  if [[ "$grdID" =~ "gfswavglo10m" ]] 
#  then
    export GRIDproc=$1
    export model=$2
    export DATA=$3
#  fi
  grdID3=`echo $grdID | cut -c1-3`
  grdID4=`echo $grdID | cut -c1-4`
echo "grdID3, grdID4: $grdID3 $grdID4"

cd $DATA
#XXX
echo "===================================================="
   echo "Values"
   echo "job:      $job"
   echo "grdID:      $grdID"
   echo "GRIDproc: $GRIDproc"
   echo "model:    $model"
   echo "DATA:     $DATA"
   echo "cyc:      $cyc"
echo "===================================================="
#XXX
NAGRIB=nagrib_nc

entry=`grep "^$grdID " $NAGRIB_TABLE | awk 'index($1,"#") != 1 {print $0}'`

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
  echo "fhcnt: $fhcnt"

#  if [ $fhcnt -ge 100 ] ; then
#    typeset -Z3 fhr
#  else
#    typeset -Z2 fhr
#  fi
  if [ $fhcnt -ge 100 ] ; then
  fhr=$fhcnt
  fhr3=$fhcnt
  elif [ $fhcnt -ge 10 ] ; then
  fhr=0$fhcnt
  fhr3=0$fhcnt
  elif [ $fhcnt -gt 0 ] ; then
  fhr=00$fhcnt
  fhr3=00$fhcnt
  else
  fhr=$fhcnt
  fhr3=$fhcnt
  fi

####  fhr=$fhcnt
  echo "fhr: $fhr"
  echo "fhr3: $fhr3"
#  fhr3=$fhcnt
#  typeset -Z3 fhr3
  GRIBIN=$COMIN/${model}.${cycle}.${GRIB}${fhr}${EXT}
  GEMGRD=${grdID}_${PDY}${cyc}f${fhr3}
#XXX filenames stil to be fixed, [global.0p16, global.0p25 =>?]

  case $grdID in
   gfswavglo10m) GRIBIN=$COMIN/${model}.${cycle}.global.0p16.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gdaswavglo10m) GRIBIN=$COMIN/${model}.${cycle}.global.0p16.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gfswavglo15mxt) GRIBIN=$COMIN/${model}.${cycle}.global.0p25.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gfswavaoc9km) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gfswavant9km) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gdasglobal0p16) GRIBIN=$COMIN/${model}.${cycle}.global.0p16.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gdasglobal0p25) GRIBIN=$COMIN/${model}.${cycle}.global.0p25.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gdasarctic9km) GRIBIN=$COMIN/${model}.${cycle}.arctic.9km.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   gdasantarc9km) GRIBIN=$COMIN/${model}.${cycle}.antarc.9km.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   nww3 | nah | nph)  
         GRIBIN=$COMIN/${model}.${cycle}.${GRIB}
         GEMGRD=${GRIDproc}_${PDY}${cyc} ;;
    akw | wna | enp)  
         GRIBIN=$COMIN/${model}.${cycle}.${GRIB}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc} 
         NAGRIB=nagrib2 ;;
   mww3) GRIBIN=$COMIN/multi_1.glo_30m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3ak10m) GRIBIN=$COMIN/multi_1.ak_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3ak4m) GRIBIN=$COMIN/multi_1.ak_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wna10m) GRIBIN=$COMIN/multi_1.at_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wna4m) GRIBIN=$COMIN/multi_1.at_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wc10m) GRIBIN=$COMIN/multi_1.wc_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3wc4m) GRIBIN=$COMIN/multi_1.wc_4m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
   mww3enp10m) GRIBIN=$COMIN/multi_1.ep_10m.${cycle}.f${fhr3}.grib2
         GEMGRD=${GRIDproc}_${PDY}${cyc}f${fhr3}
         NAGRIB=nagrib2 ;;
  esac

  if [ $grdID = "nww3" -o $grdID = "nah" -o $grdID = "nph" ] ; then
    GRIBIN_chk=$COMIN/${model}.${cycle}.${GRIB}done 
  elif [ $grdID = "akw" -o $grdID = "wna" -o $grdID = "enp" ] ; then
    GRIBIN_chk=$GRIBIN.idx
  elif [ $grdID4 = "mww3" ]; then
    GRIBIN_chk=$GRIBIN.idx
  else
    GRIBIN_chk=$GRIBIN
  fi

  icnt=1
#XXX  while [ $icnt -lt 1000 ]
  while [ $icnt -lt 3 ]
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
     if [ $grdID = "ecmwf_hr" -o $grdID = "ecmwf_wave" ] ; then
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
# GOOD grdID
set +x
echo "**************JOB $grdID NAWIPS COMPLETED NORMALLY ON THE DELL"
echo "**************JOB $grdID NAWIPS COMPLETED NORMALLY ON THE DELL"
echo "**************JOB $grdID NAWIPS COMPLETED NORMALLY ON THE DELL"
set -x
#####################################################################


############################### END OF SCRIPT #######################
