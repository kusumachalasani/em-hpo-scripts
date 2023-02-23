import csv
import json
import sys

def create_json_from_csv(csv_file_path):
    # Define the list that will hold the final JSON data
    json_data = []

    # Create an empty list to hold the deployments
    deployments = []
    mebibyte = 1048576

    # Open the CSV file
    with open(csv_file_path, 'r') as csvfile:
        # Create a CSV reader object
        csvreader = csv.DictReader(csvfile)

        container_metrics_all = {}
        for row in csvreader:
            container_metrics = {}
            if row["cpu_request_container_avg"]:
                container_metrics["cpuRequest"] = {
                        "results": {
                            "aggregation_info": {
                                "sum": float(row["cpu_request_container_sum"]),
                                "avg": float(row["cpu_request_container_avg"]),
                                "units": "cores"
                                }
                            }
                        }
            if row["cpu_limit_container_avg"]:
                container_metrics["cpuLimit"] = {
                        "results": {
                            "aggregation_info": {
                                "sum": float(row["cpu_limit_container_sum"]),
                                "avg": float(row["cpu_limit_container_avg"]),
                                "units": "cores"
                                }
                            }
                        }
            if row["cpu_throttle_container_max"]:
                container_metrics["cpuThrottle"] = {
                        "results": {
                            "aggregation_info": {
                                "sum": float(row["cpu_throttle_container_sum"]),
                                "max": float(row["cpu_throttle_container_max"]),
                                "avg": float(row["cpu_throttle_container_avg"]),
                                "units": "cores"
                                }
                            }
                        }
            container_metrics["cpuUsage"] = {
                    "results": {
                        "aggregation_info": {
                            "sum": float(row["cpu_usage_container_sum"]),
                            "min": float(row["cpu_usage_container_min"]),
                            "max": float(row["cpu_usage_container_max"]),
                            "units": "cores"
                            }
                        }
                    }            
            if row["memory_request_container_avg"]:
                container_metrics["memoryRequest"] = {
                        "results": {
                            "aggregation_info": {
                                "sum": float(row["memory_request_container_sum"])/mebibyte,
                                "avg": float(row["memory_request_container_avg"])/mebibyte,
                                "units": "MiB"
                                }
                            }
                        }
            if row["memory_limit_container_avg"]:
                container_metrics["memoryLimit"] = {
                        "results": {
                            "aggregation_info": {
                                "sum": float(row["memory_limit_container_sum"])/mebibyte,
                                "avg": float(row["memory_limit_container_avg"])/mebibyte,
                                "units": "MiB"
                                }
                            }
                        }
            container_metrics["memoryUsage"] =  {
                    "results": {
                        "aggregation_info": {
                            "min": float(row["memory_usage_container_min"])/mebibyte,
                            "max": float(row["memory_usage_container_max"])/mebibyte,
                            "sum": float(row["memory_usage_container_sum"])/mebibyte,
                            "avg": float(row["memory_usage_container_avg"])/mebibyte,
                            "units": "MiB"
                        }
                    }
                }
            container_metrics["memoryRSS"] = {
                    "results": {
                        "aggregation_info": {
                            "min": float(row["memory_rss_usage_container_min"])/mebibyte,
                            "max": float(row["memory_rss_usage_container_max"])/mebibyte,
                            "sum": float(row["memory_rss_usage_container_sum"])/mebibyte,
                            "avg": float(row["memory_rss_usage_container_avg"])/mebibyte,
                            "units": "MiB"
                        }
                    }
                }
            
            if container_metrics:
                container_metrics_all.update(container_metrics)
           
            # Create a dictionary to hold the container information
            container = {
                "image_name": row["image_name"],
                "container_name": row["container_name"],
                "container_metrics": container_metrics_all
            }
            
            # Create a list to hold the containers
            containers = [container]
            
            # Create a dictionary to hold the deployment information
            kubernetes_objects = {
                "type": row["k8_object_type"],
                "name": row["k8_object_name"],
                "namespace": row["namespace"],
                "containers": containers
            }
           
            # Create a dictionary to hold the experiment data
            experiment = {
                "version": "1.0",
                "experiment_name": "Add_Experiment Name",
                "start_timestamp": row["interval_start"],
                "end_timestamp": row["interval_end"],
                "kubernetes_objects": kubernetes_objects
            }
            
            json_data.append(experiment)

    # Write the final JSON data to the output file
    with open("updateresults.json", "w") as json_file:
        json.dump(json_data, json_file)


filename = sys.argv[1]
create_json_from_csv(filename)


