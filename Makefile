MINIX_VERSION:= ${MINIX_VERSION}

all: test

test: build
	perl -Mstrict -cw tools/*.pl
	perlcritic --harsh tools/*.pl
	docker run --rm madworx/minix:build uname -a

build:
	export VCS_REF="$$(git rev-parse --short HEAD)" ; \
	docker build -t madworx/minix:build --build-arg=MINIX_VERSION --build-arg=VCS_REF .
	docker tag madworx/minix:build madworx/minix:$$(docker run --rm madworx/minix:build --version)

push: build
	docker push madworx/minix:$$(docker run --rm madworx/minix:build --version)

run:
	docker run -d --name minix --rm -it madworx/minix:$$(docker run --rm madworx/minix:build --version)

clean:
	rm -f *~
