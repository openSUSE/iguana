#
# spec file for package iguana
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


Name:           iguana
Version:        0.1
Release:        0
Summary:        Container enhanced initrd
License:        GPL-2.0-only
URL:            https://github.com/openSUSE/iguana
Source:         %{name}-%{version}.tar
BuildRequires:  dracut-iguana
BuildRequires:  iguana-workflow
BuildRequires:  kernel-default
BuildRequires:  make
BuildRequires:  plymouth
BuildRequires:  plymouth-dracut
BuildRequires:  plymouth-plugin-label-ft
%if 0%{?is_opensuse}
BuildRequires:  plymouth-branding-openSUSE
%else
BuildRequires:  plymouth-branding-SLE
%endif

%description

Initrd for container based, expandable installation and recovery.

%prep
%setup -q

%build
%make_build

%install
%make_install

%check
make check DESTDIR=%{buildroot}

%files
%dir %{_datadir}/iguana
%{_datadir}/iguana/*

%changelog
