#!/bin/bash

set -e

# define the following in your env
# BACKUP_MONGO_URI => the name of the original mongo instance
# MONGO_URI => mongo host URI
# MONGO_USERNAME => username for mongodb
# MONGO_PASSWORD => password to authenticate against mongodb
# MONGO_AUTH_DB => name of mongo authentication database
# AZURE_SA => Azure Storage account name
# AZURE_BLOB_CONTAINER => name of the azure storage blob container
# AZURE_SHARE_NAME => name of the azure file share
# AZURE_SOURCE_KEY => azure storage account source key
# DB => mongo db to restore
# MONGO_RESTORE_OPTS => additional restore options
# DISABLE_DELETE => when specified the backup will not be deleted

# check the mongo uri
if [ -z "$MONGO_URI" ]; then
  echo "Error: you must set the MONGO_URI environment variable"
  exit 1
fi

# check the mongo db
if [ -z "$DB" ]; then
  echo "Error: you must set the DB environment variable"
  exit 2
fi

# check the azure args
if [ -z "$AZURE_SA" ] || [ -z "$AZURE_SOURCE_KEY" ]; then
  echo "Error: you must set all Azure storage account variables AZURE_SA and AZURE_SOURCE_KEY"
  exit 3
fi

# get the azure destination type and name
if [ ! -z "${AZURE_BLOB_CONTAINER}" ]; then
  AZURE_TYPE=blob
  AZURE_CONTAINER_NAME=${AZURE_BLOB_CONTAINER}
elif [ ! -z "${AZURE_SHARE_NAME}" ]; then
  AZURE_TYPE=file
  AZURE_CONTAINER_NAME=${AZURE_SHARE_NAME}
else
  echo "Error: you must set either AZURE_BLOB_CONTAINER or AZURE_SHARE_NAME"
  exit 4
fi

# check the mongo auth params
if [ -z "$MONGO_USERNAME" ] && [ -z "$MONGO_PASSWORD" ] && [ -z "$MONGO_AUTH_DB" ]; then
  NO_AUTH=${NO_AUTH:-true}
elif [ -z "$MONGO_USERNAME" ] || [ -z "$MONGO_PASSWORD" ] || [ -z "$MONGO_AUTH_DB" ]; then
  echo "Error: you must set all the MongoDB authentication environment variables MONGO_USERNAME, MONGO_PASSWORD and MONGO_AUTH_DB"
  exit 5
fi

if [ "${DB}" = "." ] || [ "${DB}" = "*" ] || [ "${DB}" = "all" ]; then
  DB=all
  DB_ARG=
fi

DIRECTORY=$(date +%Y-%m-%d)

#BACKUP_NAME="${DB}-$(date +%Y%m%d_%H%M%S).gz"

# if prefix is enabled include the mongo uri in the backup name
if [ ! -z "${BACKUP_MONGO_URI}" ]; then
  BACKUP_NAME_PREFIX="${BACKUP_MONGO_URI//[:]/-}-"
fi

LOCAL_PATH="/data/${BACKUP_NAME_PREFIX}${DB}.gz"
REMOTE_LATEST_PATH="https://${AZURE_SA}.${AZURE_TYPE}.core.windows.net/${AZURE_CONTAINER_NAME}/latest/${BACKUP_NAME_PREFIX}${DB}-backup.gz"

date
echo "Restoring MongoDB database(s) ${DB}"

if [ ! -f "${LOCAL_PATH}" ]; then
  echo "Copying compressed archive from Azure Storage: ${REMOTE_LATEST_PATH}"
  azcopy --source "${REMOTE_LATEST_PATH}" --destination "${LOCAL_PATH}" --source-key "${AZURE_SOURCE_KEY}"
fi

echo "Restoring compressed archive to MongoDB $DB"
if [ "$NO_AUTH" = true ]
then
  mongorestore --host "${MONGO_URI}" ${DB_ARG} --archive="${LOCAL_PATH}" --gzip ${MONGO_RESTORE_OPTS//[,]/ }
else
  mongorestore --authenticationDatabase "${MONGO_AUTH_DB}" -u "${MONGO_USERNAME}" -p "${MONGO_PASSWORD}" --host "${MONGO_URI}" ${DB_ARG} --archive="${LOCAL_PATH}" --gzip ${MONGO_RESTORE_OPTS//[,]/ }
fi

if [ -z "${DISABLE_DELETE}" ]; then
  echo "Cleaning up compressed archive"
  rm "${LOCAL_PATH}"
fi

echo 'Restore complete!'
