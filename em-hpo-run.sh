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

# Describes the usage of the script
function usage() {
        echo "Usage: $0 [--trials=EXPERIMENT_TRIALS] [--slo=SLO_OBJ_FUNC] [--slo_data_row=SLO_DATA_ROW] [--slo_direction=SLO_DIRECTION] --clustertype=CLUSTER_TYPE -s BENCHMARK_SERVER -e RESULTS_DIR [--benchmark=BENCHMARK_NAME] [-n NAMESPACE] [-g TFB_IMAGE] [-i SERVER_INSTANCES] [--iter=ITERATIONS] [-d DURATION] [-w WARMUPS] [-m MEASURES] [-t THREAD] [--connection=CONNECTION] [--usertunables USER_TUNABLES]"
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
                echo "Benchmarks repo exists. Continuing to use the same."
        else
		echo "Cloning the benchmarks repo..."
                git clone https://github.com/kruize/benchmarks.git 2>/dev/null
                check_err "ERROR: git clone https://github.com/kruize/benchmarks.git failed."
                echo "done"
        fi
}

### Cleanup the benchmarks repo
function delete_repos() {
        echo "1. Deleting benchmarks repo"
        rm -rf benchmarks
}

EXPERIMENT_TRIALS=2
SLO_OBJ_FUNC="( 125 \* float(data.split(\" , \")[1]) ) / ( 150 \* float(data.split(\" , \")[2]) ) / ( (25 \* float(data.split(\" , \")[3]) )/100 )"
SLO_DATA_ROW=4
SLO_DIRECTION="maximize"
BENCHMARK_NAME="techempower"
WARMUPS=5
MEASURES=3
TOTAL_INST=1
TOTAL_ITR=1
TFB_IMAGE="kruize/tfb-qrh:1.13.2.F_mm.v1"
NAMESPACE="autotune-tfb"
THREAD="40"
DURATION="60"
CONNECTIONS="512"

# Iterate through the commandline options
while getopts s:e:w:m:i:rg:n:t:R:d:-: gopts
do
        case ${gopts} in
        -)
                case "${OPTARG}" in
			clustertype=*)
				CLUSTER_TYPE==${OPTARG#*=}
				;;
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

if [[ -z "${CLUSTER_TYPE}" || -z "${BENCHMARK_SERVER}" || -z "${RESULTS_DIR_PATH}" ]]; then
        echo "Do set the variables - CLUSTER_TYPE, BENCHMARK_SERVER and RESULTS_DIR_PATH "
        usage
fi

### Export the variables for optuna

export n_trials=${EXPERIMENT_TRIALS}
export n_jobs=1
export slo_data_row=${SLO_DATA_ROW} slo_direction=${SLO_DIRECTION}

### Export variables for benchmark
export CLUSTER_TYPE=${CLUSTER_TYPE} BENCHMARK_NAME=${BENCHMARK_NAME} BENCHMARK_SERVER=${BENCHMARK_SERVER} RESULTS_DIR=${RESULTS_DIR_PATH}
export DURATION=${DURATION} WARMUPS=${WARMUPS} MEASURES=${MEASURES} SERVER_INSTANCES=${TOTAL_INST} ITERATIONS=${TOTAL_ITR} NAMESPACE=${NAMESPACE} THREADS=${THREAD} CONNECTION=${CONNECTIONS} TFB_IMAGE=${TFB_IMAGE}

if [[ ${DB_TYPE} == "standalone" || ${DB_TYPE} == "STANDALONE" ]]; then
        export DB_TYPE=${DB_TYPE}
else
        export DB_TYPE="docker"
fi

echo ""
echo "Benchmark for the experiment is ${BENCHMARK_NAME}"
echo ""

if [[ ${BENCHMARK_NAME} == "techempower" ]]; then
        clone_repos
fi

pushd hyperparameter_tuning >/dev/null

### Cleanup old results
mkdir -p results-old
if [ -f output.txt ]; then
	echo "Moving the older results into results-old directory."
	mv output.txt total-output.txt ./results-old
fi
if [ -f experiment-data.csv ]; then
        mv experiment-data.csv ./results-old
fi

### Update the slo of experiment
sed -i "s|slo_obj_func = .*|slo_obj_func = ${SLO_OBJ_FUNC}|" experiment.py

echo ""
echo "Starting the experiments..."
echo "Each trial data will be updated in experiment-data.csv file (inside hyperparameter_tuning) and"
echo "the whole output of benchmark for each trial will be updated in total-output.txt"
echo ""

python3 optimize.py 2>&1 > ../experiment.log

if [ ! -f experiment-data.csv ]; then
       echo "The configuration generated did not succeed. Experiments failed."
fi

popd >/dev/null

echo ""
echo "Experiments complete."

