#!/bin/sh
###############################################################################
# .                                                                           #
# Jan2020 RPadilla, JHAlves  - Adding error checking                          #
#                                                                             #
###############################################################################
set -x

ymdh_rtofs=$1

# Timing has to be made relative to the single 00z RTOFS cycle for that PDY

fhr_wave=`${NHOUR} ${ymdh_rtofs} ${YMDH}`
fhr=`${NHOUR} ${ymdh_rtofs} ${PDY}00`
fext='f'

if [ ${fhr} -le 0 ]
then
# Data from nowcast phase
  fhr=`expr 48 + ${fhr}`
  fext='n'
fi 

fhr=`printf "%03d\n" ${fhr}`

curfile=rtofs_glo_2ds_${fext}${fhr}_3hrly_prog.nc

echo "FILE: $COMINcur/rtofs.${PDY}/$curfile"

if [ -s ${COMINcur}/rtofs.${PDY}/${curfile} ]
then

  mkdir -p rtofs_${fext}${fhr}
  err=$?
  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************************************************* '
    echo '*** FATAL ERROR : ERROR IN wave_prnc_cur COULD NOT CREATE  rtofs_${fext}${fhr} Dir*** '
    echo '************************************************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo " ERROR IN wave_prnc_cur COULD NOT CREATE  rtofs_${fext}${fhr} Dir" >> $wavelog
    msg="FATAL ERROR : ERROR IN ww3_outp_spec (Could not create temp directory)"
    postmsg "$jlogfile" "$msg"
    err=1;export err;${errchk} || exit ${err}
  fi

  cd rtofs_${fext}${fhr}

  ncks -x -v sst,sss,layer_density  ${COMINcur}/rtofs.${PDY}/rtofs_glo_2ds_${fext}${fhr}_3hrly_prog.nc rtofs_glo_uv_${PDY}_${fext}${fhr}.nc
  if [ -s rtofs_glo_uv_${PDY}_${fext}${fhr}.nc ]; then
    rm -f rtofs_glo_2ds_${fext}${fhr}_3hrly_prog.nc
  fi

  ncks -O -a -h -x -v Layer rtofs_glo_uv_${PDY}_${fext}${fhr}.nc rtofs_temp1.nc
  ncwa -h -O -a Layer rtofs_temp1.nc rtofs_temp2.nc
  ncrename -h -O -v MT,time rtofs_temp2.nc
  #ncdump -h rtofs_temp2.nc
  ncrename -h -O -d MT,time rtofs_temp2.nc
  ncks -v u_velocity,v_velocity rtofs_temp2.nc rtofs_temp3.nc
  mv -f rtofs_temp3.nc rtofs_glo_uv_${PDY}_${fext}${fhr}_flat.nc

# Convert to regular lat lon file

  cp ${FIXwave}/weights_rtofs_to_r4320x2160.nc ./weights.nc
  
# Interpolate to regular 5 min grid
  $CDO remap,r4320x2160,weights.nc rtofs_glo_uv_${PDY}_${fext}${fhr}_flat.nc rtofs_5min_01.nc

# Perform 9-point smoothing twice to make RTOFS data less noisy when
# interpolating from 1/12 deg RTOFS grid to 1/6 deg wave grid 
  $CDO -f nc -smooth9 rtofs_5min_01.nc rtofs_5min_02.nc
  $CDO -f nc -smooth9 rtofs_5min_02.nc rtofs_glo_uv_${PDY}_${fext}${fhr}_5min.nc

# Cleanup
  rm -f rtofs_temp[123].nc rtofs_5min_??.nc rtofs_glo_uv_${PDY}_${fext}${fhr}.nc weights.nc

  if [ ${fhr_wave} -gt ${HINDH} ] 
  then
    sed -e "s/HDRFL/F/g" ${FIXwave}/ww3_prnc.cur.rtofs_5m.inp.tmpl > ww3_prnc.inp
  else
    sed -e "s/HDRFL/T/g" ${FIXwave}/ww3_prnc.cur.rtofs_5m.inp.tmpl > ww3_prnc.inp
  fi

  rm -f cur.nc
  ln -s rtofs_glo_uv_${PDY}_${fext}${fhr}_5min.nc cur.nc
  ln -s ${DATA}/mod_def.rtofs_5m ./mod_def.ww3

  $EXECcode/ww3_prnc
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '*********************************************************************** '
    echo '*** FATAL ERROR : ERROR IN wave_prnc_cur running $EXECwave/ww3_prnc *** '
    echo '*********************************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    echo "ERROR IN wave_prnc_cur running $EXECwave/ww3_prnc " >> $wavelog
    msg="FATAL ERROR : In wave_prnc_cur running $EXECwave/ww3_prnc"
    postmsg "$jlogfile" 
    err=2;export err;${errchk} || exit ${err}
  fi
  mv -f current.ww3 ${DATA}/rtofs.${ymdh_rtofs}

  cd ${DATA}

else

  echo ' '
  set $setoff
  echo ' '
  echo '************************************** '
  echo "*** FATAL ERROR: NO CUR FILE $curfile ***  "
  echo '************************************** '
  echo ' '
  set $seton
  [[ "$LOUD" = YES ]] && set -x
  echo " FATAL ERROR: NO CUR FILE $curfile" >> $wavelog
  msg="FATAL ERROR - NO CURRENT FILE (RTOFS)"
  postmsg "$jlogfile" "$msg"
  err=3;export err;${errchk} || exit ${err}
  echo ' '

fi
