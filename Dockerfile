FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get -o Acquire::Check-Valid-Until=false update \
        && apt-get update \
	&& apt-get install -y \
            adduser \
            ca-certificates \
            curl \
            npm \
            python-support \
            python-pip \
            sudo \
        && npm install -g less less-plugin-clean-css \
        && ln -s /usr/bin/nodejs /usr/bin/node \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb \
        && echo 'c81fffae4c0914f95fb12e047a72edda5042b1c6 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && echo "postfix postfix/mailname string localhost" | debconf-set-selections \
        && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
        && apt-get update \
        && apt-get install -y postfix \
        && echo "odoo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/odoo \
        && chmod 0440 /etc/sudoers.d/odoo
        
RUN pip install azure
RUN pip install unidecode
RUN pip install ofxparse

# Grab gosu for easy step-down from root
RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
        && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu

# Install Odoo
ENV ODOO_VERSION 8.0
ENV ODOO_RELEASE 20150215
ENV ODOO_FILE_PREFIX odoo_
RUN curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/${ODOO_FILE_PREFIX}${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Retrieve Odoo public key and add Odoo nightly to repo list for further updates
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 0xdef2a2198183cbb5 \
        && echo "deb http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/ ./" >> /etc/apt/sources.list

# Run script and Odoo configuration file
COPY ./run.sh /
COPY ./openerp-server.conf /etc/odoo/

exec gosu odoo mkdir /opt/odoo/additional_addons

# Mount /var/lib/odoo to allow restoring filestore
VOLUME ["/var/lib/odoo", "/opt/odoo/additional_addons"]

EXPOSE 8069 8072

CMD /run.sh
