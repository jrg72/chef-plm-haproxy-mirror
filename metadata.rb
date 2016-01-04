name             'plm-haproxy'
maintainer       'PatientsLikeMe, Inc.'
maintainer_email 'cookbooks@patientslikeme.com'
license          'Apache 2.0'
description      'Installs/Configures plm-haproxy'
long_description 'Installs/Configures plm-haproxy'
version          '0.1.1'

depends "haproxy-ng"
depends 'plm', '~> 0.1'
