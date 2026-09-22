#!/bin/sh
# =======================================================================================
# modified from Jessie's script here:
# https://github.com/JessicaNeedham/FATES-MRV/blob/main/run_scripts/create_elm-fates-PA-MRV-multiinstance_v2.sh
# =======================================================================================

## module load python

export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_MOSART_SGLC_SWAV_SIAC_SESP
export RES=ELM_USRDAT                                
export MACH=pm-cpu
export COMPILER=gnu
export PROJECT=m2420

export SITE=ZF2    
#export PARAM_FILE=/global/homes/j/jkowalcz/BIONTE_coexistence/Param_Files_Ens1//fates_params_2pfts_ens1_0115.json
export PARAM_FILE=/global/homes/j/jkowalcz/BIONTE_coexistence/default_fates_params_2pfts_ens1_0115.json

export TAG=datm_api44_default_n0115  # give your run a name
export CASE_ROOT=/pscratch/sd/j/jkowalcz/e3sm_scratch/pm-cpu/FMDF_Cases

# update with the location of your surface and domain files
export SITE_BASE_DIR=/global/homes/j/jkowalcz/BIONTE_coexistence
export ELM_USRDAT_DOMAIN=domain_${SITE}_lnd.fv1.9x2.5_gx1v6.090206.nc
export ELM_USRDAT_SURDAT=surfdata_${SITE}_1.9x2.5_simyr2000_c180306.nc
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}/
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}/

export DIN_LOC_ROOT=/global/cfs/cdirs/e3sm/inputdata/
export DIN_LOC_ROOT_CLMFORC=/pscratch/sd/j/jkowalcz/e3sm_scratch/pm-cpu/BIONTE_DATM/

# climate data will cycle between these years
export DATM_START=1990
export DATM_STOP=2014


# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
export SOURCE_DIR=/pscratch/sd/j/jkowalcz/e3sm_scratch/pm-cpu/E3SM-api44/E3SM/cime/scripts
cd ${SOURCE_DIR}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd  ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASE_ROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`

# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT} 

cd ${CASE_NAME}

# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLM1PT
./xmlchange ELM_USRDAT_NAME=${SITE}
./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_CLMFORC}
./xmlchange DIN_LOC_ROOT=${DIN_LOC_ROOT}
./xmlchange CIME_OUTPUT_ROOT=${CASE_NAME}

./xmlchange PIO_VERSION=2

# For constant CO2
./xmlchange CCSM_CO2_PPMV=400
./xmlchange DATM_CO2_TSERIES=none
./xmlchange ELM_CO2_TYPE=constant

# PE layout
./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_LND=1
./xmlchange NTASKS_ROF=1
./xmlchange NTASKS_ESP=1

./xmlchange ROOTPE_ATM=0
./xmlchange ROOTPE_CPL=0
./xmlchange ROOTPE_GLC=0
./xmlchange ROOTPE_OCN=0
./xmlchange ROOTPE_WAV=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_LND=0
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ESP=0

./xmlchange NTHRDS_ATM=1
./xmlchange NTHRDS_CPL=1
./xmlchange NTHRDS_GLC=1
./xmlchange NTHRDS_OCN=1
./xmlchange NTHRDS_WAV=1
./xmlchange NTHRDS_ICE=1
./xmlchange NTHRDS_LND=1
./xmlchange NTHRDS_ROF=1
./xmlchange NTHRDS_ESP=1


# SPECIFY RUN TYPE PREFERENCES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange MOSART_MODE=NULL
./xmlchange ROF_GRID=null

./xmlchange DEBUG=FALSE
./xmlchange STOP_N=100 
./xmlchange RUN_STARTDATE='0001-01-01'
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=50 # how often to make restart files
./xmlchange REST_OPTION=nyears
./xmlchange RESUBMIT=0 
./xmlchange DATM_CLMNCEP_YR_START=${DATM_START}
./xmlchange DATM_CLMNCEP_YR_END=${DATM_STOP}

./xmlchange JOB_WALLCLOCK_TIME=12:00:00
./xmlchange JOB_QUEUE=regular
./xmlchange SAVE_TIMING=FALSE


# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld

# Customize ELM namelist: point to your parameter file, add any history variables you want 
cat >> user_nl_elm <<EOF
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
fates_paramfile='${PARAM_FILE}'
use_fates=.true.
use_fates_nocomp=.false.
use_fates_planthydro = .false.
use_fates_daylength_factor = .true.
fates_photosynth_acclimation = 'nonacclimating'
fates_stomatal_model = 'ballberry1987'
fates_stomatal_assimilation = 'net'
fates_leafresp_model = 'atkin2017'
fates_cstarvation_model = 'exponential'
fates_regeneration_model = 'default'
fates_hydro_solver = '2D_Picard'
fates_radiation_model = 'norman'

hist_fincl1='FATES_NPLANT_SZPF','FATES_LAI_CANOPY_SZPF','FATES_MORTALITY_CANOPY_SZPF','FATES_MORTALITY_USTORY_SZPF','FATES_DDBH_CANOPY_SZPF','FATES_DDBH_USTORY_SZPF','FATES_NPLANT_CANOPY_SZPF','FATES_NPLANT_USTORY_SZPF','FATES_MORTALITY_TERMINATION_SZPF','FATES_MORTALITY_CSTARV_SZPF','FATES_MORTALITY_HYDRAULIC_SZPF','FATES_MORTALITY_BACKGROUND_SZPF','FATES_MORTALITY_IMPACT_SZPF','FATES_NPP_SZPF','FATES_GPP_SZPF','FATES_VEGC_SZPF','FATES_BASALAREA_SZPF'

EOF

# set DATM namelist to loop through input data streams
cat >> user_nl_datm <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF

# Setup case
./case.setup
./preview_namelists


## Use ./preview_run to make sure it is set up correctly


# Make change to datm stream field info variable names
CLM1PTFILE="run/datm.streams.txt.CLM1PT.ELM_USRDAT"
sed -i '/ZBOT/d' ${CLM1PTFILE}
sed -i '/RH/d' ${CLM1PTFILE}
sed -i '/FLDS/a \        QBOT     shum' ${CLM1PTFILE}

cp run/datm.streams.txt.CLM1PT.ELM_USRDAT user_datm.streams.txt.CLM1PT.ELM_USRDAT

# Build and submit the case
#./case.build 
#./case.submit --skip-preview-namelist --mail-user jenniferkowalczyk@lbl.gov -M all
