all: build

test:
	perl -Mstrict -cw tools/*.pl
	perlcritic --harsh tools/*.pl

build:	test
	docker build -t madworx/minix .

push:
	docker push madworx/minix

run:
	docker run --rm -it madworx/minix

clean:
	rm -f *~

