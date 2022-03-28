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
#########################################################################################
#    This script is to run the benchmark as part of trial in an experiment.             #
#    All the tunables configuration from optuna are inputs to benchmark.                #
#    This script has only techempower as the benchmark.                                 #
#                                                                                       #
#########################################################################################

cpu_request=$1
memory_request=$2
quarkusthreadpoolcorethreads=$3
quarkusthreadpoolqueuesize=$4
quarkusdatasourcejdbcminsize=$5
quarkusdatasourcejdbcmaxsize=$6
FreqInlineSize=$7
MaxInlineLevel=$8
MinInliningThreshold=$9
CompileThreshold=${10}
CompileThresholdScaling=${11}
ConcGCThreads=${12}
InlineSmallCode=${13}
LoopUnrollLimit=${14}
LoopUnrollMin=${15}
MinSurvivorRatio=${16}
NewRatio=${17}
TieredStopAtLevel=${18}
TieredCompilation=${19}
AllowParallelDefineClass=${20}
AllowVectorizeOnDemand=${21}
AlwaysCompileLoopMethods=${22}
AlwaysPreTouch=${23}
AlwaysTenure=${24}
BackgroundCompilation=${25}
DoEscapeAnalysis=${26}
UseInlineCaches=${27}
UseLoopPredicate=${28}
UseStringDeduplication=${29}
UseSuperWord=${30}
UseTypeSpeculation=${31}

if [ ${BENCHMARK_NAME} == "techempower" ]; then

../benchmarks/techempower/scripts/perf/tfb-run.sh --clustertype=${CLUSTER_TYPE} -s ${BENCHMARK_SERVER} -e ${RESULTS_DIR} -g ${TFB_IMAGE} --dbtype=${DB_TYPE} --dbhost=${DB_HOST} -r -d ${DURATION} -w ${WARMUPS} -m ${MEASURES} -i ${SERVER_INSTANCES} --iter=${ITERATIONS} -n ${NAMESPACE} -t ${THREADS} --connection=${CONNECTION} --cpureq=${cpu_request} --memreq=${memory_request}M --cpulim=${cpu_request} --memlim=${memory_request}M --quarkustpcorethreads=${quarkusthreadpoolcorethreads} --quarkustpqueuesize=${quarkusthreadpoolqueuesize} --quarkusdatasourcejdbcminsize=${quarkusdatasourcejdbcminsize} --quarkusdatasourcejdbcmaxsize=${quarkusdatasourcejdbcmaxsize} --FreqInlineSize=${FreqInlineSize} --MaxInlineLevel=${MaxInlineLevel} --MinInliningThreshold=${MinInliningThreshold} --CompileThreshold=${CompileThreshold} --CompileThresholdScaling=${CompileThresholdScaling} --ConcGCThreads=${ConcGCThreads} --InlineSmallCode=${InlineSmallCode} --LoopUnrollLimit=${LoopUnrollLimit} --LoopUnrollMin=${LoopUnrollMin} --MinSurvivorRatio=${MinSurvivorRatio} --NewRatio=${NewRatio} --TieredStopAtLevel=${TieredStopAtLevel} --TieredCompilation=${TieredCompilation} --AllowParallelDefineClass=${AllowParallelDefineClass} --AllowVectorizeOnDemand=${AllowVectorizeOnDemand} --AlwaysCompileLoopMethods=${AlwaysCompileLoopMethods} --AlwaysPreTouch=${AlwaysPreTouch} --AlwaysTenure=${AlwaysTenure} --BackgroundCompilation=${BackgroundCompilation} --DoEscapeAnalysis=${DoEscapeAnalysis} --UseInlineCaches=${UseInlineCaches} --UseLoopPredicate=${UseLoopPredicate} --UseStringDeduplication=${UseStringDeduplication} --UseSuperWord=${UseSuperWord} --UseTypeSpeculation=${UseTypeSpeculation}

fi
