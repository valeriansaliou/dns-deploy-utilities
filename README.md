dns-deploy-utilities
====================

This repository is used to store and deploy DNS configurations across a pool of nameserver replicas, simultaneously.

**Be cautious on the changes you make in the configuration files. The server will run a (very) basic human error detector during the deploy process, but it cannot cover any possible case.**


## Add A New Domain

To add a new domain, you need to create a new directory **./conf/zones/example.com/** that contains 2 files:

* **db** - the zone database, containing domain records
* **zone** - the zone configuration, associating the database with the target domain root

Once done, check that you didn't make any mistake in the configuration of this new domain using:

* `named-checkzone example.com ./conf/zones/example.com/db`

If it says OK, you can move forward. Now, you have to enable this zone in **./conf/named.conf.local** by adding an include directive.


## Generate DNSSEC Key Pairs

In order to generate a DNSSEC key pairs, you need to use a system that disposes of dnssec-keygen.

When you're ready, enter the 2 commands below to generate the certificates for the domain name of your choice:

* `dnssec-keygen -a NSEC3RSASHA1 -b 2048 -n ZONE example.com`
* `dnssec-keygen -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE example.com`

**Note: for faster key generation, make sure haveged is available on your system. If not, execute:**

* `apt-get install haveged`

Then, copy the generated files in a **./keys/example.com/** directory.

The last thing to do here is to fill a form at your domain registrar's website to submit your DNSSEC keys to the root domain authority (here, .com which is managed by Verisign).


## Deploy To Production

To update nameservers zones with your zone, you first need to version your work and push it to `master`.

Once done, go to this project on GitLab, and open a new merge request from `master` to `production`. Confirm the merge request, and wait a little bit.

You should soon receive either a success or failure email from our nameservers replicas:

* **Success** - you can move forward
* **Failure** - fix the issue and retry to merge (see details in the email deploy log)


## Change Domain Nameservers

Now that your new zone is deployed and running in production, you can safely update your domain configuration with your nameservers.

Once changed, you will need to wait a little bit for the new configuration to propagate.

**We recommend that you test your domain zones using `dig` once the new configuration is effective. Try to point directly to the target DNS server using `dig @x.ns.server.tld domain.com` (replace with your nameserver domain)**


## Check Configuration

You can check the full configuration of a domain from an external validator anytime.

**It is a recommended practice to check that things still look good after a change.**

SSL Tools allows you to proceed deep checks of your domains (DNS, DNSSEC, DANE, mailservers and so on) - https://ssl-tools.net
