# cens-rstudio-cookbook

A cookbook to maintain existing rstudio installation.

## Notes/FAQs

### server pro license and NTP

If you happen to be using the rstudio pro version, and you've had trouble with the license expiring due time syncing issues, you may want to use the `ntp` cookbook as we've done in our [base cookbook](https://github.com/mobilizingcs-ops/chef-cens-base). In our KVM virt environment both the guest and host need to be running the ntpd service and (preferably) pointing at the same NTP time clock servers.  Because of the awesomeness of the KVM virt hardware clock when the host was not pointing at the same NTP server as the guest it allowed the times to swing enough to cause the license to be expired until the times came back in sync and the rstudio-server service was restarted.

## Supported Platforms

Ubuntu 12.04, Ubuntu 14.04

## License and Authors

Author:: Steve Nolen (technolengy@gmail.com)
