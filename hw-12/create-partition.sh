#!/bin/bash


table="opensky"
from="2018-12-01"

c=$(date -d ${from} +%Y-%m-01)
l=$(date -d "2021-12-01" +%Y-%m-01)
while [[ ${c} != ${l} ]]; do
	y=$(date -d ${c} +%Y)
	m=$(date -d ${c} +%m)
	n=$(date -d "$(date -d "${c} + 1 month")" +%Y-%m)
	c=$(date -I -d "${c} + 1 month")

	echo "CREATE TABLE ${table}_${y}_${m} PARTITION OF ${table} FOR VALUES FROM ('${y}-${m}-01 00:00:00') TO ('${n}-01 00:00:00');"
done
