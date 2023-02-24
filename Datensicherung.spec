#
# spec file for package Datensicherung
#
# Copyright (c) 2023 SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           Datensicherung
Version:        0
Release:        0
Summary:        Daten sicher kopieren
License:        GPL-2.0-only
URL:            https://github.com/olafhering/scripts/tree/Datensicherung
BuildRequires:  systemd-rpm-macros
%{?systemd_requires}
Requires:       chrony
Requires:       kbd
Requires:       coreutils
Requires:       ntfs-3g
Requires:       rsnapshot
Requires:       rsync
Requires:       time
Requires:       util-linux-systemd

%description

%prep
rm -rf %_builddir/%name-%version
mv %_sourcedir/%name-%version %_builddir/%name-%version
%setup -c -T -D
%autopatch -p1

%build
sed -i~ '
s@/usr/lib/Datensicherung.sh@%_libexecdir/%name.sh@g
' Datensicherung.service
diff -u "$_"~ "$_" && : gleich

%install
mkdir -p %buildroot%_libexecdir
mv -t %buildroot%_libexecdir %name.sh
mkdir -p %buildroot%_unitdir
mv -t %buildroot%_unitdir %name.service

%pre
%service_add_pre %name.service
%post
%service_add_post %name.service
%preun
%service_del_preun %name.service
%postun  
%service_del_postun_without_restart %name.service

%files
%config %attr(555,-,-) %_libexecdir/%name.sh
%config %attr(444,-,-) %_unitdir/%name.service

%changelog
