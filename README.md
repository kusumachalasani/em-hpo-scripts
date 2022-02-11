# EM-HPO-SCRIPTS

This repo consists of scripts to run HyperParamater Optimization algorithms with TechEmpower Quarkus benchmark.

## To run an autotune experiment

```
./em-hpo-run.sh [--trials=EXPERIMENT_TRIALS] [--slo=SLO_OBJ_FUNC] [--slo_data_row=SLO_DATA_ROW] -s BENCHMARK_SERVER -e RESULTS_DIR [--benchmark=BENCHMARK_NAME] [-n NAMESPACE] [-g TFB_IMAGE] [-i SERVER_INSTANCES] [--iter=ITERATIONS] [-d DURATION] [-w WARMUPS] [-m MEASURES] [-t THREAD] [--connection=CONNECTION] [--usertunables USER_TUNABLES]

Example:
./em-hpo-run.sh --trials=2 --slo="( float(data.split(\" , \")[1]) )" --slo_data_row=4 -s cluster-a.scalelab -e ./results ---benchmark=techempower -n autotune-tfb -g kusumach/tfb-qrh:1.13.2.F_mm_p -i 1 --iter=3 -d 60 -w 3 -m 3 -t 48 --connection=512 --usertunables="-server;-XX:+UseG1GC"

- **EXPERIMENT_TRIALS**: No.of trials in an experiment
- **SLO_OBJ_FUNC**: SLO Objective Function
- **SLO_DATA_ROW**: Which row is to be considered to parse the metrics for SLO. Default is based on techempower benchmark.
- **BENCHMARK_SERVER**: Name of the cluster you are using
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
```

## List of files to update tunables to run an experiment with benchmark.

| Script Name   |  Updates required for 														    |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| tunables.py   | search_space_json to include the direction of objective function, HPO algorithm, tunables with lower bound, upperbound and the step value | 
| experiment.py | tunables in function get_experiment_result					    |
| applyconfig.sh| script to use for benchmark run													    |


For details on HyperParamter tuning, read [this](https://github.com/kruize/autotune/blob/master/hyperparameter_tuning/README.md)
