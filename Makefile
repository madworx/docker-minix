all: test

test: build
	perl -Mstrict -cw tools/*.pl
	perlcritic --harsh tools/*.pl
	docker run --rm madworx/minix uname -a

build:
	export VCS_REF="$$(git rev-parse --short HEAD)" ; \
	docker build -t madworx/minix --build-arg=VCS_REF .

push:
	docker push madworx/minix

run:
	docker run -d --name minix --rm -it madworx/minix

clean:
	rm -f *~
