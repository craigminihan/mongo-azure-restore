#! /usr/bin/env bash

if [ $# -eq 1 ] && [ "$1" == "bash" ]; then
    ENTRYPOINT="--entrypoint bash"
else
    while [[ $# -gt 0 ]]
    do
        key="${1}"
        case ${key} in
        -u|--url)
            MONGO_URI="${2}"
            shift
            ;;
        -n|--username)
            MONGO_USERNAME="${2}"
            shift # past argument
            ;;
        -p|--password)
            MONGO_PASSWORD="${2}"
            shift # past argument
            ;;
        -a|--auth-db)
            MONGO_AUTH_DB="${2}"
            shift # past argument
            ;;
        --sa)
            AZURE_SA="${2}"
            shift # past argument
            ;;
        -c|--blob-container)
            AZURE_BLOB_CONTAINER="${2}"
            shift # past argument
            ;;
        -s|--share-name)
            AZURE_SHARE_NAME="${2}"
            shift # past argument
            ;;
        -k|--key)
            AZURE_SOURCE_KEY="${2}"
            shift # past argument
            ;;
        --db)
            DB="${2}"
            shift # past argument
            ;;
        -b|--backup-uri)
            BACKUP_MONGO_URI="${2}"
            shift # past argument
            ;;
        -o|--restore-options)
            if [ ! -z "${MONGO_RESTORE_OPTS}" ]; then MONGO_RESTORE_OPTS+=","; fi
            MONGO_RESTORE_OPTS+="${2}"
            shift # past argument
            ;;
        -i|--include)
            if [ ! -z "${MONGO_RESTORE_OPTS}" ]; then MONGO_RESTORE_OPTS+=","; fi
            MONGO_RESTORE_OPTS+="--nsInclude=${2}"
            shift # past argument
            ;;
        -x|--exclude)
            if [ ! -z "${MONGO_RESTORE_OPTS}" ]; then MONGO_RESTORE_OPTS+=","; fi
            MONGO_RESTORE_OPTS+="--nsExclude=${2}"
            shift # past argument
            ;;
        -d|--drop)
            if [ ! -z "${MONGO_RESTORE_OPTS}" ]; then MONGO_RESTORE_OPTS+=","; fi
            MONGO_RESTORE_OPTS+="--drop"
            ;;
        -t|--threads)
            if [ ! -z "${MONGO_RESTORE_OPTS}" ]; then MONGO_RESTORE_OPTS+=","; fi
            MONGO_RESTORE_OPTS+="--numParallelCollections=${2}"
            shift # past argument
            ;;
        *)  # unknown option
            shift # past argument
            ;;
        esac
        shift
    done

    ENV_ARGS="-e MONGO_URI=${MONGO_URI} -e MONGO_USERNAME=${MONGO_USERNAME} -e MONGO_PASSWORD=${MONGO_PASSWORD} -e MONGO_AUTH_DB=${MONGO_AUTH_DB} -e AZURE_SA=${AZURE_SA} "
    ENV_ARGS+="-e AZURE_BLOB_CONTAINER=${AZURE_BLOB_CONTAINER} -e AZURE_SHARE_NAME=${AZURE_SHARE_NAME} -e AZURE_SOURCE_KEY=${AZURE_SOURCE_KEY} -e DB=${DB} "
    ENV_ARGS+="-e BACKUP_MONGO_URI=${BACKUP_MONGO_URI} -e MONGO_RESTORE_OPTS=${MONGO_RESTORE_OPTS}"
fi

docker run -ti --rm ${ENTRYPOINT} ${ENV_ARGS} mongo-azure-restore:test
