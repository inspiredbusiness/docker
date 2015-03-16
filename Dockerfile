FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update \
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
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
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

# Install Odoo
ENV ODOO_VERSION 7.0
ENV ODOO_RELEASE 20150215
ENV ODOO_FILE_PREFIX openerp_
RUN curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/${ODOO_FILE_PREFIX}${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Run script and Odoo configuration file
COPY ./run.sh /
RUN chmod +x ./run.sh
COPY ./openerp-server.conf /etc/openerp/
RUN chown openerp /etc/odoo/openerp-server.conf

RUN mkdir -p /opt/openerp/additional_addons \
    && chown odoo /opt/openerp/additional_addons

# Mount /var/lib/odoo to allow restoring filestore
#"/var/lib/odoo", 
VOLUME ["/opt/openerp/additional_addons"]

EXPOSE 8069 8072

ENTRYPOINT ["bash /run.sh"]
