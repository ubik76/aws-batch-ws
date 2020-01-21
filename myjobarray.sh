#!/bin/bash


filename=job-$AWS_BATCH_JOB_ID-$AWS_BATCH_JOB_ARRAY_INDEX.out
date >> $filename
echo "Args: $@" >> $filename
#env >> $filename
echo "This is my simple test job!." >> $filename
echo "jobId: $AWS_BATCH_JOB_ID" >> $filename
sleep $1 >> $filename
date >> $filename
echo "bye bye!!" >> $filename

aws s3 cp $filename $EXPORT_S3_BUCKET_URL
