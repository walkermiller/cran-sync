FROM public.ecr.aws/docker/library/alpine:latest

RUN apk update
RUN apk add --no-cache rsync
RUN apk add --no-cache aws-cli
COPY cran-s3-sync.sh /cran-s3-sync.sh

ENTRYPOINT [ "sh" ]
CMD ["/cran-s3-sync.sh"]
