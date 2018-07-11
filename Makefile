all: build

test:
	shellcheck -s ksh tools/*.sh
	perl -Mstrict -cw tools/*.pl
	perlcritic --harsh tools/*.pl

build:	test
	docker build -t madworx/minix .

run:
	docker run --rm -it madworx/minix

clean:
	rm -f *~

