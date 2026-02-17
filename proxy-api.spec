Name:           proxy-api
Version:        1.0
Release:        1%{?dist}
Summary:        Python Flask Proxy with Redis caching
License:        MIT
Source0:        proxy-api-1.0.tar.gz
BuildArch:      noarch
Requires:       python3, python3-flask, python3-redis, python3-requests, python36-PyYAML

%description
Proxy service that checks Redis before calling Backend API.

%prep
# -n указывает имя папки, которая создается ПРИ РАСПАКОВКЕ архива
%setup -q -n proxy-api-1.0

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/etc/cache-api
mkdir -p %{buildroot}/lib/systemd/system

install -m 755 %{_builddir}/proxy-api-1.0/proxy.py %{buildroot}/usr/bin/proxy-api
install -m 644 %{_builddir}/proxy-api-1.0/config.yaml %{buildroot}/etc/cache-api/config.yaml

# Создание systemd unit прямо в процессе сборки
cat <<EOF > %{buildroot}/lib/systemd/system/proxy-api.service
[Unit]
Description=Proxy API Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/bin/proxy-api
Environment=CONFIG_PATH=/etc/cache-api/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

%files
/usr/bin/proxy-api
/etc/cache-api/config.yaml
/lib/systemd/system/proxy-api.service

%post
systemctl daemon-reload
systemctl enable proxy-api
systemctl start proxy-api
