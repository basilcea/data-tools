#!/bin/bash

folders=("retail_db/categories" "retail_db/customers" "retail_db/departments" "retail_db/order_items" "retail_db/orders" "retail_db/products")
bucket="s3://mcea-datadev/"

# Loop through each folder and sync to S3
for folder in "${folders[@]}"; do
  aws s3 sync "$folder" "$bucket$folder"
done