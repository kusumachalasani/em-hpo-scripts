# EM-HPO-SCRIPTS

This repo consists of scripts to run HyperParamater Optimization algorithms with TechEmpower Quarkus benchmark.

## Prerequisites
- Enable monitoring for user-defined projects.
- Packages required on client machine : python36 php java11 git wget zip bc jq.

To enable monitring for user-defined projects on openshift:

1. Edit the cluster-monitoring-config ConfigMap object:
   ```
        $ oc -n openshift-monitoring edit configmap cluster-monitoring-config
   ```
2. Add enableUserWorkload: true under data/config.yaml:
   ```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cluster-monitoring-config
      namespace: openshift-monitoring
    data:
      config.yaml: |
        enableUserWorkload: true
   ```
3. Save the file to apply the changes. Monitoring for user-defined projects is then enabled automatically.
4. Check that the prometheus-operator, prometheus-user-workload and thanos-ruler-user-workload pods are running in the openshift-user-workload-monitoring project. It might take a short while for the pods to start:
   ```
        oc -n openshift-user-workload-monitoring get pod
   ```
For more details on enabling monitoring, check [this](https://docs.openshift.com/container-platform/4.6/monitoring/enabling-monitoring-for-user-defined-projects.html)

## To run an autotune experiment

```
./em-hpo-run.sh [--trials=EXPERIMENT_TRIALS] [--slo=SLO_OBJ_FUNC] [--slo_data_row=SLO_DATA_ROW] [--slo_direction=SLO_DIRECTION] --clustertype=CLUSTER_TYPE -s BENCHMARK_SERVER -e RESULTS_DIR [--benchmark=BENCHMARK_NAME] [-n NAMESPACE] [-g TFB_IMAGE] [-i SERVER_INSTANCES] [--iter=ITERATIONS] [-d DURATION] [-w WARMUPS] [-m MEASURES] [-t THREAD] [--connection=CONNECTION] [--usertunables USER_TUNABLES]

For the techempower benchmark with default options, run as
./em-hpo-run.sh --trials=2 --clustertype=<CLUSTER_TYPE> -s <BENCHMARK_SERVER> -e ./results ---benchmark=techempower

To customize other options:
./em-hpo-run.sh --trials=2 --slo="( 125 \* float(data.split(\" , \")[1]) ) / ( 150 \* float(data.split(\" , \")[2]) ) / ( (25 \* float(data.split(\" , \")[3]) )/100 )" --slo_data_row=4 --slo-direction="maximize" --clustertype=openshift -s cluster-a -e ./results ---benchmark=techempower -n autotune-tfb -g kruize/tfb-qrh:1.13.2.F_mm_p -i 1 --iter=3 -d 60 -w 3 -m 3 -t 48 --connection=512 --usertunables="-server;-XX:+UseG1GC"

- **EXPERIMENT_TRIALS**: No.of trials in an experiment
- **SLO_OBJ_FUNC**: SLO Objective Function. Default is "( 125 * throughput ) / ( 150 * responsetime) / ( ( 25 * maxresponsetime) /100 )"
- **SLO_DATA_ROW**: Which row is to be considered to parse the metrics for SLO. Default is based on techempower benchmark.
- **SLO_DIRECTION**: Direction of SLO_OBJ_FUNC. Supports minimize and maximize
- **CLUSTER_TYPE**: Type of cluster. Supports openshift and minikube.
- **BENCHMARK_SERVER**: Name of the cluster where the benchmark is run.
- **RESULTS_DIR**: Directory to store results
- **BENCHMARK_NAME**: Name of the benchmark. Default is techempower
- **DB_TYPE**: Supports only options : DOCKER , STANDALONE. Default is DOCKER.
- **DB_HOST**: Hostname of the database if DB_TYPE selected is STANDALONE.
- **SERVER_INSTANCES**: Number of tfb-qrh instances to be deployed. It is optional, if is not specified then by default it will be considered as 1 instance.
- **NAMESPACE**: Namespace in which tfb-qrh application is to be deployed. It is optional, if not specified then `default` will be considered as the namespace.
- **TFB_IMAGE**: TechEmpower Framework Quarkus image to deploy. It is optional, if is not specified then the default image `kruize/tfb-qrh:1.13.2.F_mm.v1` will be considered for the deployment.
- **DURATION**: Duration of each warmup and measurement run.
- **WARMUPS**: No.of warmup runs.
- **MEASURES**: No.of measurement runs.
- **ITERATIONS**: No.of iterations.
- **THREADS**: No.of threads used by hyperfoil/wrk2 client
- **CONNECTION**: No.of connections used by hyperffoil/wrk2
- **USER_TUNABLES**: Any specific tunable user want to mention. If there are multiple entires, it should be separated by ; and enclosed with ""

For a sample output of benchmark, 
INSTANCES , THROUGHPUT , RESPONSE_TIME , MAX_RESPONSE_TIME
1 , 6288.45 , 42.1948 , 2162.504393000

SLO_DATA_ROW is the second row which will be 1.
SLO_OBJ_FUNC mentioned above is converted as "( 125 \* float(data.split(\" , \")[1]) ) / ( 150 \* float(data.split(\" , \")[2]) ) / ( (25 \* float(data.split(\" , \")[3]) )/100 )"
SLO_DIRECTION is maximize
```

## Output of an Autotune Experiment
Output of all trials in an experiment will be updated to experiment-data.csv
Recommendation of best config will be displayed in the console at the end of the experiment.
```
**Sample recommendation:**
INFO - bayes_optuna.optuna_hpo - Best parameter: {'cpuRequest': 2.99, 'memoryRequest': 3631, 'quarkusthreadpoolcorethreads': 20, 'quarkusthreadpoolqueuesize': 7870, 'quarkusdatasourcejdbcminsize': 6, 'quarkusdatasourcejdbcmaxsize': 52, 'FreqInlineSize': 447, 'MaxInlineLevel': 24, 'MinInliningThreshold': 121, 'CompileThreshold': 9640, 'CompileThresholdScaling': 10.3, 'ConcGCThreads': 1, 'InlineSmallCode': 2955, 'LoopUnrollLimit': 235, 'LoopUnrollMin': 1, 'MinSurvivorRatio': 11, 'NewRatio': 6, 'TieredStopAtLevel': 4, 'TieredCompilation': 'true', 'AllowParallelDefineClass': 'true', 'AllowVectorizeOnDemand': 'true', 'AlwaysCompileLoopMethods': 'false', 'AlwaysPreTouch': 'false', 'AlwaysTenure': 'false', 'BackgroundCompilation': 'false', 'DoEscapeAnalysis': 'false', 'UseInlineCaches': 'true', 'UseLoopPredicate': 'false', 'UseStringDeduplication': 'true', 'UseSuperWord': 'true', 'UseTypeSpeculation': 'false'}
INFO - bayes_optuna.optuna_hpo - Best value: 0.12
INFO - bayes_optuna.optuna_hpo - Best trial: FrozenTrial(number=0, values=[0.12], datetime_start=datetime.datetime(2022, 2, 15, 12, 2, 14, 430545), datetime_complete=datetime.datetime(2022, 2, 15, 12, 10, 53, 323447), params={'cpuRequest': 2.99, 'memoryRequest': 3631, 'quarkusthreadpoolcorethreads': 20, 'quarkusthreadpoolqueuesize': 7870, 'quarkusdatasourcejdbcminsize': 6, 'quarkusdatasourcejdbcmaxsize': 52, 'FreqInlineSize': 447, 'MaxInlineLevel': 24, 'MinInliningThreshold': 121, 'CompileThreshold': 9640, 'CompileThresholdScaling': 10.3, 'ConcGCThreads': 1, 'InlineSmallCode': 2955, 'LoopUnrollLimit': 235, 'LoopUnrollMin': 1, 'MinSurvivorRatio': 11, 'NewRatio': 6, 'TieredStopAtLevel': 4, 'TieredCompilation': 'true', 'AllowParallelDefineClass': 'true', 'AllowVectorizeOnDemand': 'true', 'AlwaysCompileLoopMethods': 'false', 'AlwaysPreTouch': 'false', 'AlwaysTenure': 'false', 'BackgroundCompilation': 'false', 'DoEscapeAnalysis': 'false', 'UseInlineCaches': 'true', 'UseLoopPredicate': 'false', 'UseStringDeduplication': 'true', 'UseSuperWord': 'true', 'UseTypeSpeculation': 'false'}, distributions={'cpuRequest': DiscreteUniformDistribution(high=4.0, low=1.0, q=0.01), 'memoryRequest': IntUniformDistribution(high=4096, low=270, step=1), 'quarkusthreadpoolcorethreads': IntUniformDistribution(high=32, low=1, step=1), 'quarkusthreadpoolqueuesize': IntUniformDistribution(high=10000, low=0, step=10), 'quarkusdatasourcejdbcminsize': IntUniformDistribution(high=12, low=1, step=1), 'quarkusdatasourcejdbcmaxsize': IntUniformDistribution(high=90, low=12, step=1), 'FreqInlineSize': IntUniformDistribution(high=500, low=325, step=1), 'MaxInlineLevel': IntUniformDistribution(high=50, low=9, step=1), 'MinInliningThreshold': IntUniformDistribution(high=200, low=0, step=1), 'CompileThreshold': IntUniformDistribution(high=10000, low=1000, step=10), 'CompileThresholdScaling': DiscreteUniformDistribution(high=15.0, low=1.0, q=0.1), 'ConcGCThreads': IntUniformDistribution(high=8, low=1, step=1), 'InlineSmallCode': IntUniformDistribution(high=5000, low=500, step=1), 'LoopUnrollLimit': IntUniformDistribution(high=250, low=20, step=1), 'LoopUnrollMin': IntUniformDistribution(high=20, low=0, step=1), 'MinSurvivorRatio': IntUniformDistribution(high=48, low=3, step=1), 'NewRatio': IntUniformDistribution(high=10, low=1, step=1), 'TieredStopAtLevel': IntUniformDistribution(high=4, low=0, step=1), 'TieredCompilation': CategoricalDistribution(choices=('true', 'false')), 'AllowParallelDefineClass': CategoricalDistribution(choices=('true', 'false')), 'AllowVectorizeOnDemand': CategoricalDistribution(choices=('true', 'false')), 'AlwaysCompileLoopMethods': CategoricalDistribution(choices=('true', 'false')), 'AlwaysPreTouch': CategoricalDistribution(choices=('true', 'false')), 'AlwaysTenure': CategoricalDistribution(choices=('true', 'false')), 'BackgroundCompilation': CategoricalDistribution(choices=('true', 'false')), 'DoEscapeAnalysis': CategoricalDistribution(choices=('true', 'false')), 'UseInlineCaches': CategoricalDistribution(choices=('true', 'false')), 'UseLoopPredicate': CategoricalDistribution(choices=('true', 'false')), 'UseStringDeduplication': CategoricalDistribution(choices=('true', 'false')), 'UseSuperWord': CategoricalDistribution(choices=('true', 'false')), 'UseTypeSpeculation': CategoricalDistribution(choices=('true', 'false'))}, user_attrs={}, system_attrs={}, intermediate_values={}, trial_id=0, state=TrialState.COMPLETE, value=None)
INFO - bayes_optuna.optuna_hpo - Recommended config: {'id': 'auto123', 'application_name': 'benchmark-deployment-1234', 'direction': 'maximize', 'optimal_value': {'objective_function': {'name': 'transaction_response_time', 'value': 0.12, 'value_type': 'double'}, 'tunables': [{'name': 'cpuRequest', 'value': 2.99, 'value_type': 'double'}, {'name': 'memoryRequest', 'value': 3631, 'value_type': 'integer'}, {'name': 'quarkusthreadpoolcorethreads', 'value': 20, 'value_type': 'integer'}, {'name': 'quarkusthreadpoolqueuesize', 'value': 7870, 'value_type': 'integer'}, {'name': 'quarkusdatasourcejdbcminsize', 'value': 6, 'value_type': 'integer'}, {'name': 'quarkusdatasourcejdbcmaxsize', 'value': 52, 'value_type': 'integer'}, {'name': 'FreqInlineSize', 'value': 447, 'value_type': 'integer'}, {'name': 'MaxInlineLevel', 'value': 24, 'value_type': 'integer'}, {'name': 'MinInliningThreshold', 'value': 121, 'value_type': 'integer'}, {'name': 'CompileThreshold', 'value': 9640, 'value_type': 'integer'}, {'name': 'CompileThresholdScaling', 'value': 10.3, 'value_type': 'double'}, {'name': 'ConcGCThreads', 'value': 1, 'value_type': 'integer'}, {'name': 'InlineSmallCode', 'value': 2955, 'value_type': 'integer'}, {'name': 'LoopUnrollLimit', 'value': 235, 'value_type': 'integer'}, {'name': 'LoopUnrollMin', 'value': 1, 'value_type': 'integer'}, {'name': 'MinSurvivorRatio', 'value': 11, 'value_type': 'integer'}, {'name': 'NewRatio', 'value': 6, 'value_type': 'integer'}, {'name': 'TieredStopAtLevel', 'value': 4, 'value_type': 'integer'}, {'name': 'TieredCompilation', 'value': 'true', 'value_type': 'categorical'}, {'name': 'AllowParallelDefineClass', 'value': 'true', 'value_type': 'categorical'}, {'name': 'AllowVectorizeOnDemand', 'value': 'true', 'value_type': 'categorical'}, {'name': 'AlwaysCompileLoopMethods', 'value': 'false', 'value_type': 'categorical'}, {'name': 'AlwaysPreTouch', 'value': 'false', 'value_type': 'categorical'}, {'name': 'AlwaysTenure', 'value': 'false', 'value_type': 'categorical'}, {'name': 'BackgroundCompilation', 'value': 'false', 'value_type': 'categorical'}, {'name': 'DoEscapeAnalysis', 'value': 'false', 'value_type': 'categorical'}, {'name': 'UseInlineCaches', 'value': 'true', 'value_type': 'categorical'}, {'name': 'UseLoopPredicate', 'value': 'false', 'value_type': 'categorical'}, {'name': 'UseStringDeduplication', 'value': 'true', 'value_type': 'categorical'}, {'name': 'UseSuperWord', 'value': 'true', 'value_type': 'categorical'}, {'name': 'UseTypeSpeculation', 'value': 'false', 'value_type': 'categorical'}]}}

**experiment-data.csv**
INSTANCES,THROUGHPUT_RATE_3m,RESPONSE_TIME_RATE_3m,MAX_RESPONSE_TIME,RESPONSE_TIME_50p,RESPONSE_TIME_95p,RESPONSE_TIME_97p,RESPONSE_TIME_99p,RESPONSE_TIME_99.9p,RESPONSE_TIME_99.99p,RESPONSE_TIME_99.999p,RESPONSE_TIME_100p,CPU_USAGE,MEM_USAGE,CPU_MIN,CPU_MAX,MEM_MIN,MEM_MAX,THRPT_PROM_CI,RSPTIME_PROM_CI,THROUGHPUT_WRK,RESPONSETIME_WRK,RESPONSETIME_MAX_WRK,RESPONSETIME_STDEV_WRK,WEB_ERRORS,THRPT_WRK_CI,RSPTIME_WRK_CI,CPU_REQ,MEM_REQ,CPU_LIM,MEM_LIM,QRKS_TP_CORETHREADS,QRKS_TP_QUEUESIZE,QRKS_DS_JDBC_MINSIZE,QRKS_DS_JDBC_MAXSIZE,FreqInlineSize,MaxInlineLevel,MinInliningThreshold,CompileThreshold,CompileThresholdScaling,ConcGCThreads,InlineSmallCode,LoopUnrollLimit,LoopUnrollMin,MinSurvivorRatio,NewRatio,TieredStopAtLevel,TieredCompilation,AllowParallelDefineClass,AllowVectorizeOnDemand,AlwaysCompileLoopMethods,AlwaysPreTouch,AlwaysTenure,BackgroundCompilation,DoEscapeAnalysis,UseInlineCaches,UseLoopPredicate,UseStringDeduplication,UseSuperWord,UseTypeSpeculation
1,12069.4,10.0251,34801.534532000,0.3,2.1,3.5,20.4,99.3,107.3,140.2,231.6,0.78081,484.202,.02853138683272716,1.3357821665101048,257,576,0,0,14978.5,34.25,1510.00,39.55,0,,,2.99,3631M,2.99,3631M,20,7870,6,52,447,24,121,9640,10.3,1,2955,235,1,11,6,4,true,true,true,false,false,false,false,false,true,false,true,true,false
```

## List of files to update tunables to run an experiment with benchmark.

| Script Name   |  Updates required for 														    |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| tunables.py   | search_space_json to include the direction of objective function, HPO algorithm, tunables with lower bound, upperbound and the step value | 
| experiment.py | tunables in function get_experiment_result					    |
| applyconfig.sh| script to use for benchmark run													    |


For details on HyperParamter tuning, read [this](https://github.com/kruize/autotune/blob/master/hyperparameter_tuning/README.md)

For details on techempower benchmark, read [this](https://github.com/kruize/benchmarks/blob/master/techempower/README.md)
