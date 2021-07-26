# AWS Batch workshop

This workshop assumes that you run in the AWS **Oregon** Region (us-west-2)

## Workshop setup
* Login to the Event Engine
    * https://dashboard.eventengine.run/dashboard

* Start the Cloud9 IDE
    * https://www.hpcworkshops.com/02-aws-getting-started/04-start_cloud9.html
* Create and S3 Bucket:
    * `BUCKET_POSTFIX=$(uuidgen --random | cut -d'-' -f1)`
    * `aws s3 mb s3://batch-workshop-${BUCKET_POSTFIX}`
    * Take note of the bucket name you have just created

## Prepare the Docker image

* Download the workshop example code:

    * `git clone https://github.com/ubik76/aws-batch-ws`
    * `cd aws-batch-ws`

* Edit the shell scripts to be executable
    * `chmod a+x *.sh`

* Create the docker image
    * `docker build -t awsbatch/fetch_and_run .`
* Create an ECR repository
    * `aws ecr create-repository --repository-name fetch-and-run`
    * `ECR_REPOSITORY_URI=$(aws ecr describe-repositories --repository-names fetch-and-run --output text --query 'repositories[0].[repositoryUri]')`

* Push the docker image to the repository:
    * `$(aws ecr get-login --no-include-email --region us-west-2)`
    * `docker tag awsbatch/fetch_and_run:latest $ECR_REPOSITORY_URI`
    * `docker push $ECR_REPOSITORY_URI`

* Configure IAM role
    * In the IAM console, choose **Roles**, **Create New Role**.
    * Under type of trusted entity, choose **AWS service** then **Elastic Container Service**.
    * For use case, select **Elastic Container Service Task**, and choose Next: Permissions.
    * On the Attach Policy page, type “AmazonS3FullAccess” into the Filter field and then select the check box for that policy. Then, choose Next:Tags
    * Add the Tag, for example: Key=Name; Value=workshop
    * Enter a name for your new role, for example: **batchJobRole**, and choose Create Role. You will see the details of the new role.

* Create a simple job script and upload to S3
    * Replace <bucket> with the S3 bucket name you have created before
    * `aws s3 cp myjob.sh s3://batch-workshop-${BUCKET_POSTFIX}/myjob.sh`
    * `aws s3 cp myjobarray.sh s3://batch-workshop-${BUCKET_POSTFIX}/myjobarray.sh`




## Configure AWS Batch
  
### Create Your Compute Environment
    
Compute environments can be seen as a computational cluster. They can consist of one or several instance kinds or just the number of cores you would like in it. 

To create a compute environment we will follow these steps:

* Select Managed Compute Environment (CE), to let AWS Batch manage the auto-scaling of EC2 resources for you.
* Name your Compute Environment.
* In Service Role, let Batch create a new service Role so it can manage resources on your behalf.
* In "Additional Settings", in Instance Role, let Batch create a new instance Role
* Leave the EC2 key-pair empty


Once done scroll down to configure the rest of the CE (please use the default values for the other parameters)

  * Provisioning model: SPOT
  * Maximum Price: 100
  * Allowed Instance Types: optimal
  * Allocation Strategy: SPOT_CAPACITY_OPTIMIZED
  * Add a tag called "Name" and as a value choose a name for your instances created with Batch
  * Then click on Create to build your new Compute Environment.

### Setup a Job Queue
Now we will setup a Job Queue. This is where you will submit your jobs. Those will be dispatched to the Compute Environment(s) of your choosing by order of priority.

* Chose a name for your queue, for example "test-queue"
* Define a priority (1-500). This defines the priority of a Job Queue when a Compute environment is shared accross Job Queues (for example a Production Job Queue with a priority of 500 and a R&D Job Queue with a priority of 250).
*  Select the Compute Environment created previously.
* Then create your Job Queue.

### Setup a Job Definition

Go the the Job Definition screen and create a new one.

* Select a job definition name, for example "test-def"
* Input 5 for the number of attempts before declaring a job as failed.
* Input 100 for the time between attempts in seconds.


![Screenshot of Job Definition #1](/images/job-definition-10.png)

* Add the container image with the repositoryUri generated when creating our ECR repository. If in doubt, check the URI from the ECR console or you can get the URI by running the command below in your terminal: 

    `aws ecr describe-repositories --repository-names fetch-and-run --output text --query 'repositories[0].[repositoryUri]'`

* For vCPUs, enter 1. For Memory, enter 500

![Screenshot of Job Definition #2](/images/job-definition-20.png)

* In "Additional configuration", add the job role previously defined for ECS tasks to access the output S3 bucket on your behalf.
* Set "Execution Role" to "None".
* In the Security panel, enter “nobody” for "User".

![Screenshot of Job Definition #3](/images/job-definition-30.png)

* Choose Create job definition.

### Describe your environment
Now what we configured Batch, let’s take a look at what we have with the following commands

* `aws batch describe-compute-environments`
* `aws batch describe-job-queues`
* `aws batch describe-job-definitions`

### Run your first job

* In the AWS Batch console, choose Jobs, Submit Job.

* Enter a name for the job, for example: `test`.

* Choose the latest job definition.
* For Job Queue, choose the queue you have defined before, for example: test-queue.

![Screenshot of Job #1](/images/job-run-10.png)


* For Command, enter `myjob.sh 60`.

![Screenshot of Job #2](/images/job-run-20.png)

* Environment Variable

     This will tell to the application running in your container where to export data. Use the variable name EXPORT_S3_BUCKET_URL and the value corresponds to the bucket you have previously created.
     
     You have to specify also the BATCH_FILE_S3_URL to your script and the type of file (BATCH_FILE_TYPE), for example:
     
    * `BATCH_FILE_S3_URL=s3://batch-workshop-87d7dd41/myjob.sh`
    * `BATCH_FILE_TYPE=script`

![Screenshot of Job #3](/images/job-run-30.png)

* Click on "Submit" to start your first job


### Try also from the command line:
* Edit the `submit-json` file according to your configuration and then submit the job via the CLI:
* `aws batch submit-job --cli-input-json file://submit.json`	
