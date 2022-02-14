#!/bin/bash
#
# Copyright (c) 2021, 2022 Red Hat, IBM Corporation and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

CLUSTER_TYPE="openshift"
TFB_DEFAULT_IMAGE="kruize/tfb-qrh:1.13.2.F_mm.v1"

# Describes the usage of the script
function usage() {
        echo "Usage: $0 [--trials=EXPERIMENT_TRIALS] [--slo=SLO_OBJ_FUNC] [--slo_data_row=SLO_DATA_ROW] [--slo_direction=SLO_DIRECTION] -s BENCHMARK_SERVER -e RESULTS_DIR [--benchmark=BENCHMARK_NAME] [-n NAMESPACE] [-g TFB_IMAGE] [-i SERVER_INSTANCES] [--iter=ITERATIONS] [-d DURATION] [-w WARMUPS] [-m MEASURES] [-t THREAD] [--connection=CONNECTION] [--usertunables USER_TUNABLES]"
        exit -1
}

function check_err() {
        err=$?
        if [ ${err} -ne 0 ]; then
                echo "$*"
                exit 1
        fi
}

### Clone the repos
function clone_repos() {
        if [ -d benchmarks ]; then
                echo "benchmarks dir exist. Continue to use the existing repo."
        else
                echo
                echo "#######################################"
                git clone https://github.com/kruize/benchmarks.git 2>/dev/null
                check_err "ERROR: git clone https://github.com/kruize/benchmarks.git failed."
                echo "done"
                echo "#######################################"
                echo
        fi
}

### Cleanup the benchmarks repo
function delete_repos() {
        echo "1. Deleting benchmarks repo"
        rm -rf benchmarks
}

# Iterate through the commandline options
while getopts s:e:w:m:i:rg:n:t:R:d:-: gopts
do
        case ${gopts} in
        -)
                case "${OPTARG}" in
                        trials=*)
                                EXPERIMENT_TRIALS=${OPTARG#*=}
                                ;;
                        slo=*)
                                SLO_OBJ_FUNC=${OPTARG#*=}
                                ;;
                        slo_data_row=*)
                                SLO_DATA_ROW=${OPTARG#*=}
                                ;;
			slo_direction=*)
				SLO_DIRECTION=${OPTARG#*=}
				;;
                        benchmark=*)
                                BENCHMARK_NAME=${OPTARG#*=}
                                ;;
                        iter=*)
                                TOTAL_ITR=${OPTARG#*=}
                                ;;
                        dbtype=*)
                                DB_TYPE=${OPTARG#*=}
                                ;;
                        dbhost=*)
                                DB_HOST=${OPTARG#*=}
                                export DB_HOST=${DB_HOST}
                                ;;
                        usertunables=*)
                                OPTIONS_VAR=${OPTARG#*=}
                                export OPTIONS_VAR=${OPTIONS_VAR}
                                ;;
                        connection=*)
                                CONNECTIONS=${OPTARG#*=}
                                ;;
                        *)
                esac
                ;;

        s)
                BENCHMARK_SERVER="${OPTARG}"
                ;;
        e)
                RESULTS_DIR_PATH="${OPTARG}"
                export RESULTS_DIR=${RESULTS_DIR_PATH}
                ;;
        w)
                WARMUPS="${OPTARG}"
                ;;
        m)
                MEASURES="${OPTARG}"
                ;;
        i)
                TOTAL_INST="${OPTARG}"
                ;;
        r)
                RE_DEPLOY="true"
                ;;
        g)
                TFB_IMAGE="${OPTARG}"
                ;;
        n)
                NAMESPACE="${OPTARG}"
                ;;
        t)
                THREAD="${OPTARG}"
                ;;
        d)
                DURATION="${OPTARG}"
                ;;
        esac
done

if [[ -z "${BENCHMARK_SERVER}" || -z "${RESULTS_DIR_PATH}" ]]; then
        echo "Do set the variables - BENCHMARK_SERVER and RESULTS_DIR_PATH "
        usage
fi

if [ -z "${EXPERIMENT_TRIALS}" ]; then
        EXPERIMENT_TRIALS=2
fi

if [ -z "${SLO_OBJ_FUNC}" ]; then
        SLO_OBJ_FUNC="( 125 \* float(data.split(\" , \")[1]) ) / ( 150 \* float(data.split(\" , \")[2]) ) / ( (25 \* float(data.split(\" , \")[3]) )/100 )"
fi

if [ -z "${SLO_DATA_ROW}" ]; then
        SLO_DATA_ROW=4
fi

if [ -z "${SLO_DIRECTION}" ]; then
        SLO_DIRECTION="maximize"
fi

if [ -z "${BENCHMARK_NAME}" ]; then
        BENCHMARK_NAME="techempower"
fi

if [ -z "${WARMUPS}" ]; then
        WARMUPS=5
fi
if [ -z "${MEASURES}" ]; then
        MEASURES=3
fi

if [ -z "${TOTAL_INST}" ]; then
        TOTAL_INST=1
fi

if [ -z "${TOTAL_ITR}" ]; then
        TOTAL_ITR=1
fi

if [ -z "${RE_DEPLOY}" ]; then
        RE_DEPLOY=false
fi

if [ -z "${TFB_IMAGE}" ]; then
        TFB_IMAGE="${TFB_DEFAULT_IMAGE}"
fi

if [ -z "${NAMESPACE}" ]; then
        NAMESPACE="autotune-tfb"
fi

if [ -z "${THREAD}" ]; then
        THREAD="40"
fi

if [ -z "${DURATION}" ]; then
        DURATION="60"
fi

if [ -z "${CONNECTIONS}" ]; then
        CONNECTIONS="512"
fi

### Export the variables for optuna

export n_trials=${EXPERIMENT_TRIALS}
export n_jobs=1
export slo_data_row=${SLO_DATA_ROW} slo_direction=${SLO_DIRECTION}

### Export variables for benchmark
export BENCHMARK_NAME=${BENCHMARK_NAME}
export BENCHMARK_SERVER=${BENCHMARK_SERVER} DURATION=${DURATION} WARMUPS=${WARMUPS} MEASURES=${MEASURES} SERVER_INSTANCES=${TOTAL_INST} ITERATIONS=${TOTAL_ITR} NAMESPACE=${NAMESPACE} THREADS=${THREAD} CONNECTION=${CONNECTIONS} TFB_IMAGE=${TFB_IMAGE}

if [[ ${DB_TYPE} == "standalone" || ${DB_TYPE} == "STANDALONE" ]]; then
        export DB_TYPE=${DB_TYPE}
else
        export DB_TYPE="docker"
fi

echo ""
echo "Benchmark used to run experiment is ${BENCHMARK_NAME}"
echo ""

if [[ ${BENCHMARK_NAME} == "techempower" ]]; then
        clone_repos
fi

pushd hyperparameter_tuning >/dev/null

### Cleanup old results
mkdir -p results-old
if [ -f output.txt ]; then
        mv output.txt total-output.txt ./results-old
fi
if [ -f experiment-data.csv ]; then
        mv experiment-data.csv ./results-old
fi

### Update the slo of experiment
sed -i "s|slo_obj_func = .*|slo_obj_func = ${SLO_OBJ_FUNC}|" experiment.py

echo ""
echo "Starting the experiments. Visit experiment.log for the progress of the run."
echo "Each trial data will be updated in experiment-data.csv file (inside hyperparameter_tuning)."
echo ""

python3 optimize.py 2>&1 > ../experiment.log

popd >/dev/null

echo "Experiments complete."
echo "View the recommended config in experiment.log"

