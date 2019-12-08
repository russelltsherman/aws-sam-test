-include $(shell curl -sSL -o .build-harness "https://raw.githubusercontent.com/opsbot/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

PACKAGED_TEMPLATE = packaged.yaml
S3_BUCKET := $(S3_BUCKET)
STACK_NAME := $(STACK_NAME)
TEMPLATE = template.yaml

## Sets up a local endpoint you can use to test your API.
api: build
	sam local start-api
.PHONY: api

## Provision project dependencies
bootstrap: deps
.PHONY: bootstrap

## Build functions for distribution
build: clean deps
	GOOS=linux GOARCH=amd64 go build -o hello-world/hello-world ./hello-world
.PHONY: build

## Clean build artifacts
clean: 
	rm -rf ./hello-world/hello-world
.PHONY: clean

## Deploy
deploy: package
	sam deploy --stack-name $(STACK_NAME) --template-file $(PACKAGED_TEMPLATE) --capabilities CAPABILITY_IAM
.PHONY: deploy

## Fetch go module dependencies
deps: go.mod
	@go mod download
.PHONY: deps

## ensure go.mod config file exists
go.mod:
	go mod init

package: build
	sam package --template-file $(TEMPLATE) --s3-bucket $(S3_BUCKET) --output-template-file $(PACKAGED_TEMPLATE)
.PHONY: package

## execute unit tests	
test:
	go test -v ./hello-world/
.PHONY: test

## Update project and dependencies
update: 
	@make refresh-build-harness
	@git fetch
	git update
	make bootstrap
.PHONY: update
