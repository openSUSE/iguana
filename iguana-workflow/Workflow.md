# Iguana workflow file syntax

This document provides overview and explanation of the iguana workflow file.

__Iguana workflow is under active development and this document is subject to change.__

## name (Optional)

The name of the workflow.

## env (Optional)

List of environmental variables to be passed to all containers defined in this workflow.

## jobs (Mandatory)

Workflow consists of one or more jobs specified under _jobs_ map. Jobs run __sequentially__ by default in order specified in the workflow file.

## jobs.\<jobid\> (Mandatory)

Unique name of the job.

## jobs.\<jobid\>.container (Mandatory)

Map containing basic information about container to run. Job container is started in interactive mode and __workflow waits__ until container job is finished.

## jobs.\<jobid\>.container.image (Mandatory)

Image name or URL of the image to download from the registry. May contain image tag.

## jobs.\<jobid\>.container.env (Optional)

List of environmental variables to be passed to the container.

## jobs.\<jobid\>.container.volumes (Optional)

List of volumes to be created and mounted to the container:

```
volumes:
  - my_volume:/mnt/volume
  - /mnt/volume
  - /srv/volume:/data
```

## jobs.\<jobid\>.services (Optional)

Map of service containers to be started in parallel to the main job container. These containers are started in background, stopped and cleaned after main job container finishes.

## jobs.\<jobid\>.services.\<serviceid\> (Mandatory)

Name of the service, unique for job.

## jobs.\<jobid\>.services.\<serviceid\>.image (Mandatory)

Image name or URL of the image to download from the registry. May contain image tag.

## jobs.\<jobid\>.services.\<serviceid\>.env (Optional)

List of environmental variables to be passed to the container.

## jobs.\<jobid\>.services.\<serviceid\>.volumes (Optional)

List of volumes to be created and mounted to the container. See [job container volumes](#jobsjobidcontainervolumes-optional)

## jobs.\<jobid\>.needs (Optional)

Name of the job that must be successfuly finished for this job to start.

By default if container run fails, workflow continue with other job. Specifying __needs__ option, workflow starts this job only when previous job successfuly finished.