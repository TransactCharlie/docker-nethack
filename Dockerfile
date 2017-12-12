FROM alpine:latest AS hackbuild

RUN apk update
RUN apk add byacc
RUN apk add flex
RUN apk add gcc
RUN apk add libc-dev
RUN apk add linux-headers
RUN apk add make
RUN apk add ncurses-static ncurses-dev

# Get Nethack
RUN wget -O- https://github.com/NetHack/NetHack/archive/NetHack-3.6.0.zip | unzip -

WORKDIR /NetHack-NetHack-3.6.0/

# set the syntax for flex and cp in the hints file
# and use a fixed directory
RUN cat sys/unix/hints/linux-chroot > hints && \
echo '#-POST' >> hints && \
echo 'LEX = flex' >> hints && \
sed -i -e 's/^HACKDIR=.*/HACKDIR=\/nh360/' hints && \
sed -i -e 's/cp -n/cp /g' hints && \
sed -i -e "/^CFLAGS/s/-O/-Os -fomit-frame-pointer/" hints && \
sed -i -e 's/-lcurses/-lncursesw/g' hints && \
echo 'LFLAGS=-static' >> hints && \
sh ./sys/unix/setup.sh hints

RUN HOME= make
RUN HOME= make install

WORKDIR /

# Final Container
FROM alpine:latest
COPY --from=hackbuild /etc/terminfo/ /etc/terminfo/
COPY --from=hackbuild /nh/install/nh360 /nh360
COPY defaults.nh /nh360/defaults.nh
COPY sysconf /nh360/sysconf
ENV NETHACKOPTIONS=@/nh360/defaults.nh
ENTRYPOINT ["/nh360/nethack"]
