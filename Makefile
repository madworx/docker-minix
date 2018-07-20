all: test

test: build
	perl -Mstrict -cw tools/*.pl
	perlcritic --harsh tools/*.pl
	docker run --rm madworx/minix uname -a

build:
	docker build -t madworx/minix .

push:
	docker push madworx/minix

run:
	docker run -d --name minix --rm -it madworx/minix

clean:
	rm -f *~
