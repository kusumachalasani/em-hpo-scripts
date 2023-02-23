import pandas as pd
import os

# Load the CSV file into a pandas DataFrame
df = pd.read_csv('cop-0223.csv')

#Remove the rows if there is no owner_kind, owner_name and workload
columns_to_check = ['owner_kind', 'owner_name', 'workload', 'workload_type']
df = df.dropna(subset=columns_to_check, how='any')

#df.to_csv('cop-ch.csv', index=False)
#df = pd.read_csv('cop-ch.csv')

# Create a column with k8_object_type
df['k8_object_type'] = ''
for i, row in df.iterrows():
    if row['owner_kind'] == 'ReplicaSet' and row['workload'] == '<none>':
        df.at[i, 'k8_object_type'] = 'ReplicaSet'
    elif row['owner_kind'] == 'ReplicationController' and row['workload'] == '<none>':
        df.at[i, 'k8_object_type'] = 'ReplicaSet'
    else:
        df.at[i, 'k8_object_type'] = row['workload_type']

#df.to_csv('cop-withobjType.csv', index=False)
#df = pd.read_csv('cop-withobjType.csv')

# Update k8_object_name based on the type and workload.
df['k8_object_name'] = ''
for i, row in df.iterrows():
    if row['workload'] != '<none>':
        df.at[i, 'k8_object_name'] = row['workload']
    else:
        df.at[i, 'k8_object_name'] = row['owner_name']

df.to_csv('cop-withobjType.csv', index=False)


# Create a temporary file to append the aggregate data from multiple files.
# Extract the header row
#header_row = df.columns.tolist()

# Create a new DataFrame with no rows but with the same columns as the existing file
#new_df = pd.DataFrame(columns=header_row)
#new_df.to_csv('cop-agg.csv', index=False)


# Specify the columns to sort by
#sort_columns = ['namespace', 'k8_object_type', 'owner_name', 'image_name', 'container_name', 'interval_start'] 
sort_columns = ['namespace', 'k8_object_type', 'workload', 'container_name', 'interval_start']
sorted_df = df.sort_values(sort_columns)

# Group the rows by the unique values
grouped = sorted_df.groupby(sort_columns)

# Create a directory to store the output CSV files
output_dir = 'output'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Write each group to a separate CSV file
counter = 0
for key, group in grouped:
    counter += 1
    filename = f"file_{counter}.csv"
#    filename = '_'.join(str(x) for x in key) + '.csv'
    filepath = os.path.join(output_dir, filename)
    print(filepath)
    group.to_csv(filepath, index=False)


#Create a temporary file to append the aggregate data from multiple files.
# Extract the header row
header_row = df.columns.tolist()

# Create a new DataFrame with no rows but with the same columns as the existing file
agg_df = pd.DataFrame(columns=header_row)
#new_df.to_csv('cop-agg.csv', index=False)

#agg_df = pd.read_csv('cop-agg.csv')

for filename in os.listdir(output_dir):
    if filename.endswith('.csv'):
        filepath = os.path.join(output_dir, filename)

        # Read the CSV file into a pandas dataframe
        df = pd.read_csv(filepath)
       
        # Calculate the average and minimum values for specific columns
        for column in df.columns:
            if column.endswith('avg'):
                avg = df[column].mean()
                df[column] = avg
            elif column.endswith('min'):
                minimum = df[column].min()
                df[column] = minimum
            elif column.endswith('max'):
                maximum = df[column].max()
                df[column] = maximum
            elif column.endswith('sum'):
                total = df[column].sum()
                df[column] = total
                
        df.to_csv('output.csv', index=False)
        agg_df = agg_df.append(df)

agg_df.to_csv('final.csv', index=False)

# Generate unique metric rows
# list of column names to ignore
columns_to_ignore = ['pod', 'owner_name', 'node' , 'resource_id']
df1 = pd.read_csv('final.csv')

# Drop duplicates while ignoring the specified columns
df1 = df1.drop_duplicates(subset=[col for col in df.columns if col not in columns_to_ignore])

# Drop the columns which are not required (optional)
df1.drop(columns_to_ignore, axis=1, inplace=True)

df1.to_csv('metrics.csv', index=False)
