name 'cens-rstudio'
maintainer 'Steve Nolen'
maintainer_email 'technolengy@gmail.com'
license 'Apache 2.0'
description 'Installs/Configures cens-rstudio'
long_description 'Installs/Configures cens-rstudio'
version '0.0.7'

%w(ubuntu).each do |os|
  supports os
end

depends 'nginx', '~>2.7.6'
depends 'R'
