Outline
-------

This is a 'dark loading' proxy written in Sinatra (written in a rush, so no hatin' :-). The idea here is to create a proxy that allows a user to run multiple PuppetDB systems in parallel, but only trust the data from the first one. This is so you can run up a second PuppetDB and see how it handles load.

This is prototype code, so if you aren't able to fix Ruby code, don't use it :-).

Caveats
-------

* This code is slow
* Doesn't thread to multiplex, everything is sequential
* Doesn't support chunked encoding, even though PuppetDB often does.
* Really bad docs - YMMV
* Not production ready - YMMV
* Only supports GET and POST today
* No tests
* Probably lots of bugs. Patches accepted.

Installation
------------

Tested with:

* Apache2
* Passenger > 3.3.x (from package)
* Debian 7
* bundler (from package)

Steps:

* Copy the project somewhere on your host
* Hand modify server.rb and put the list of downstream servers
* From the project dir use bundler to do: bundle install --path=vendor/bundle
* Configure apache for SSL termination, this is based roughly on the Puppet one, but it enforces client authentication at the Apache layer:

        # you probably want to tune these settings
        PassengerHighPerformance on
        PassengerMaxPoolSize 12
        PassengerPoolIdleTime 1500
        # PassengerMaxRequests 1000
        PassengerStatThrottleRate 120
        RackAutoDetect Off
        RailsAutoDetect Off
        
        Listen 6666
        
        <VirtualHost *:6666>
                SSLEngine on
                SSLProtocol -ALL +SSLv3 +TLSv1
                SSLCipherSuite ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP
        
                SSLCertificateFile      /etc/puppet/ssl/certs/puppetdb1.vm.pem
                SSLCertificateKeyFile   /etc/puppet/ssl/private_keys/puppetdb1.vm.pem
                SSLCertificateChainFile /etc/puppet/ssl/certs/ca.pem
                SSLCACertificateFile    /etc/puppet/ssl/certs/ca.pem
                # If Apache complains about invalid signatures on the CRL, you can try disabling
                # CRL checking by commenting the next line, but this is not recommended.
                SSLCARevocationFile     /etc/puppet/ssl/ca/ca_crl.pem
                SSLVerifyClient require
                SSLVerifyDepth  1
                SSLOptions +StdEnvVars
        
                # This header needs to be set if using a loadbalancer or proxy
                RequestHeader unset X-Forwarded-For
        
                RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
                RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
                RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e
        
                DocumentRoot /mnt/hgfs/Development/dark-loader-proxy/public
                RackBaseURI /
                <Directory /mnt/hgfs/Development/dark-loader-proxy/public>
                        Options None
                        AllowOverride None
                        Order allow,deny
                        allow from all
                </Directory>
        </VirtualHost>

* Restart, and configure your puppetdb.conf to use the port and host where you configured this instead.
