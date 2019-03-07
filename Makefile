BASE_NAME=ghostscript
VERSION=9.26
SHORT:=$(subst .,,$(VERSION))
STACK_NAME:=$(BASE_NAME)-lambda-layer

default: deploy

clean:
	rm -rf build

check_vars:
ifndef DEPLOYMENT_BUCKET
	$(error DEPLOYMENT_BUCKET is undefined)
endif

build/ghostscript/bin:
	mkdir -p build/bin
	cd build/bin ;\
	curl -sL https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$(SHORT)/ghostscript-$(VERSION)-linux-x86_64.tgz | tar zx ;\
	mv ghostscript-$(VERSION)-linux-x86_64/gs-$(SHORT)-linux-x86_64 gs ;\
	rm -rf ghostscript-$(VERSION)-linux-x86_64

build/ghostscript/lib:
	mkdir -p build/share/ghostscript/lib
	cd build/share/ghostscript/lib ;\
	curl -sL https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$(SHORT)/ghostscript-$(VERSION).tar.gz | tar zx ;\
	mv ghostscript-$(VERSION)/lib/* . ;\
	rm -rf ghostscript-$(VERSION)

build/ghostscript: check_vars build/ghostscript/bin build/ghostscript/lib

build/layer: build/ghostscript
	cd build ;\
	zip -r layer.zip bin share

deploy: build/layer
	aws cloudformation package --template-file template.yml --s3-bucket $(DEPLOYMENT_BUCKET) --s3-prefix $(STACK_NAME) --output-template-file package.yml
	aws cloudformation deploy --template-file package.yml --stack-name $(STACK_NAME)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs[].OutputValue --output text
