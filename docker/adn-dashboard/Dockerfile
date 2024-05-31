FROM php:apache-bullseye
COPY config/adndash-default.conf /etc/apache2/sites-available/
COPY config/adnsdash-default-ssl.conf /etc/apache2/sites-available/
COPY config/gencert.sh /usr/local/bin/
COPY entrypoint /entrypoint
RUN chmod +x /usr/local/bin/gencert.sh
RUN echo Install needed packages... && \
    apt-get update && \
    apt-get -y install cron python3 python3-pip git gcc libffi-dev libssl-dev cargo sed && \
    pip3 install --no-cache-dir bitstring bitarray Twisted dmr_utils3 configparser resettabletimer \
    setproctitle Pyro5 spyne setuptools wheel autobahn jinja2 MarkupSafe pyOpenSSL service-identity && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo Creating ADN Dashboard folder... && \
    mkdir -p /opt/adn-dashboard && \
    echo Modify Apache config... && \
    echo '<Directory /opt/adn-dashboard/>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride None\n\
    Require all granted\n\
    </Directory>' >> /etc/apache2/apache2.conf && \
    echo Enable Apache stuff... && \
    a2enmod proxy rewrite proxy_http proxy_wstunnel ssl socache_shmcb headers && \
    a2dissite adnsdash-default-ssl.conf 000-default.conf default-ssl.conf && \
    a2ensite adndash-default.conf && \
    echo Cleaning stuff... && \
    apt-get purge -y git gcc libffi-dev libssl-dev cargo && \
    apt-get autoremove -y && \
    echo Adding Cron stuff... && \
    mkdir -p /var/spool/crontabs && \
    echo "50 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null" > /var/spool/crontabs/root && \
    echo DONE

RUN chmod +x /entrypoint
ENTRYPOINT [ "/entrypoint" ]
