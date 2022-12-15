#
# spec file for package dracut-iguana
#
# Copyright (c) 2022 SUSE LLC
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


Name:           dracut-iguana
Version:        0.1
Release:        0
Summary:        Container based dracut module
License:        GPL-2.0-only
Group:          System/Packages
URL:            https://github.com/aaannz/iguana
Source:         %{name}-%{version}.tar
BuildRequires:  dracut
Requires:       curl
Requires:       dracut
Requires:       grep
Requires:       iguana-workflow
Requires:       iproute2
Requires:       kexec-tools
Requires:       podman
Requires:       procps
Requires:       wicked
BuildArch:      noarch

%description
Dracut module adding container boot workflow

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_prefix}/lib/dracut/modules.d/50iguana
cp -R iguana/* %{buildroot}%{_prefix}/lib/dracut/modules.d/50iguana
chmod 755 %{buildroot}%{_prefix}/lib/dracut/modules.d/50iguana/*

%files
%{_prefix}/lib/dracut/modules.d/50iguana

%changelog
