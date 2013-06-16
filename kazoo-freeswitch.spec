%define packagelayout   FH
%define PREFIX          %{_prefix}
%define EXECPREFIX      %{_exec_prefix}
%define BINDIR          %{_bindir}
%define SBINDIR         %{_sbindir}
%define LIBDIR          %{_libdir}
%define INCLUDEDIR      %{_includedir}
%define DATADIR         %{_datadir}
%define INFODIR         %{_infodir}
%define MANDIR          %{_mandir}
%define MODINSTDIR      %{_libdir}/freeswitch/mod
%define LIBEXECDIR      %{_libexecdir}/freeswitch
%define SYSCONFDIR      %{_sysconfdir}/kazoo/freeswitch
%define SHARESTATEDIR   %{_sharedstatedir}/freeswitch
%define DOCDIR          %{_defaultdocdir}/freeswitch
%define HTMLDIR         %{_defaultdocdir}/freeswitch/html
%define DVIDIR          %{_defaultdocdir}/freeswitch/dvi
%define PDFDIR          %{_defaultdocdir}/freeswitch/pdf
%define PSDIR           %{_defaultdocdir}/freeswitch/ps
%define RUNDIR          %{_localstatedir}/run/freeswitch
%define DATAROOTDIR     %{_prefix}/share
%define LOCALEDIR       %{_prefix}/share/locale
%define HTDOCSDIR       %{_prefix}/share/freeswitch/htdocs
%define SOUNDSDIR       %{_prefix}/share/freeswitch/sounds
%define GRAMMARDIR      %{_prefix}/share/freeswitch/grammar
%define SCRIPTDIR       %{_prefix}/share/freeswitch/scripts
%define PKGCONFIGDIR    %{_prefix}/share/freeswitch/pkgconfig
%define LOCALSTATEDIR   %{_localstatedir}/lib/freeswitch
%define DBDIR           %{_localstatedir}/lib/freeswitch/db
%define RECORDINGSDIR   %{_localstatedir}/lib/freeswitch/recordings
%define HOMEDIR         %{_localstatedir}/lib/freeswitch
%define LOGFILEDIR      /var/log/freeswitch

Name:           kazoo-freeswitch
Summary:        FreeSWITCH open source telephony platform
License:        MPL1.1
Group:          Productivity/Telephony/Servers
Version:        v1.2.10
Release:        2600hz%{?dist}
URL:            http://www.freeswitch.org/
Packager:       Karl Anderson
Vendor:         http://www.Kazoo.org/

Source0:        Kazoo-FreeSWITCH.tar
Source1:        celt-0.10.0.tar.gz
Source2:        flite-1.5.1-current.tar.bz2
Source3:        lame-3.97.tar.gz
Source4:        libshout-2.2.2.tar.gz
Source5:        mpg123-1.13.2.tar.gz

BuildRequires: make
BuildRequires: pkgconfig
BuildRequires: autoconf
BuildRequires: automake
BuildRequires: curl-devel
BuildRequires: gcc-c++
BuildRequires: libtool >= 1.5.17
BuildRequires: ncurses-devel
BuildRequires: openssl-devel
BuildRequires: gawk
BuildRequires: libjpeg-devel
BuildRequires: libtiff-devel
BuildRequires: openssl-devel

BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
This is a build of FreeSWITCH (http://www.freeswitch.org/) by 2600hz.  All credit and respect goes to 
those hard-working folks!  Hope to see you at ClueCon (https://www.cluecon.com/) 
        --Karl Senior Bit Herder 2600hz

FreeSWITCH is an open source telephony platform designed to facilitate the creation of voice
and chat driven products scaling from a soft-phone up to a soft-switch.  It can be used as a
simple switching engine, a media gateway or a media server to host IVR applications using
simple scripts or XML to control the callflow.

We support various communication technologies such as SIP, H.323 and GoogleTalk making
it easy to interface with other open source PBX systems such as sipX, OpenPBX, Bayonne, YATE or Asterisk.

We also support both wide and narrow band codecs making it an ideal solution to bridge legacy
devices to the future. The voice channels and the conference bridge module all can operate
at 8, 16 or 32 kilohertz and can bridge channels of different rates.

FreeSWITCH runs on several operating systems including Windows, Max OS X, Linux, BSD and Solaris
on both 32 and 64 bit platforms.

Our developers are heavily involved in open source and have donated code and other resources to
other telephony projects including Kazoo, sipXecs, OpenSER, Asterisk, CodeWeaver and OpenPBX.

######################################################################################################################
# Prepare for the build
######################################################################################################################
%prep
%setup -b0 -q -n Kazoo-FreeSWITCH

cp %{SOURCE1} libs/
cp %{SOURCE2} libs/
cp %{SOURCE3} libs/
cp %{SOURCE4} libs/
cp %{SOURCE5} libs/

%{__mkdir} -p %{buildroot}%{LOGFILEDIR}
%{__mkdir} -p %{buildroot}%{RUNDIR}
%{__mkdir} -p %{buildroot}%{LOCALSTATEDIR}
%{__mkdir} -p %{buildroot}%{DBDIR}
%{__mkdir} -p %{buildroot}%{GRAMMARDIR}/model/communicator
%{__mkdir} -p %{buildroot}%{HTDOCSDIR}
%{__mkdir} -p %{buildroot}%{LOGFILEDIR}
%{__mkdir} -p %{buildroot}%{RUNDIR}
%{__mkdir} -p %{buildroot}%{SCRIPTDIR}

%ifos linux
# Install init files
# On SuSE make /usr/sbin/rcfreeswitch a link to /etc/rc.d/init.d/freeswitch
%if 0%{?suse_version} > 100
%{__install} -D -m 744 %{_builddir}/Kazoo-FreeSWITCH/build/freeswitch.init.suse %{buildroot}/etc/rc.d/init.d/freeswitch
%{__mkdir} -p %{buildroot}/usr/sbin
%{__ln_s} -f /etc/rc.d/init.d/freeswitch %{buildroot}/usr/sbin/rcfreeswitch
%else
# On RedHat like
%{__install} -D -m 0755 %{_builddir}/Kazoo-FreeSWITCH/build/freeswitch.init.redhat %{buildroot}/etc/rc.d/init.d/freeswitch
%endif
# Add the sysconfiguration file
%{__install} -D -m 744 %{_builddir}/Kazoo-FreeSWITCH/build/freeswitch.sysconfig %{buildroot}/etc/sysconfig/freeswitch
# Add monit file
%{__install} -D -m 644 %{_builddir}/Kazoo-FreeSWITCH/build/freeswitch.monitrc %{buildroot}/etc/monit.d/freeswitch.monitrc
%endif

######################################################################################################################
# Bootstrap, Configure and Build the whole enchilada
######################################################################################################################
%build

export MODULES="loggers/mod_console \
loggers/mod_logfile \
loggers/mod_syslog \
applications/mod_commands \
applications/mod_dptools \
applications/mod_spandsp \
applications/mod_conference \
applications/mod_http_cache \
applications/mod_channel_move \
dialplans/mod_dialplan_directory \
dialplans/mod_dialplan_xml \
endpoints/mod_loopback \
endpoints/mod_sofia \
event_handlers/mod_event_socket \
event_handlers/mod_kazoo \
formats/mod_sndfile \
formats/mod_local_stream \
formats/mod_tone_stream \
formats/mod_shout \
codecs/mod_amr \
codecs/mod_amrwb \
codecs/mod_bv \
codecs/mod_celt \
codecs/mod_codec2 \
codecs/mod_g723_1 \
codecs/mod_g729 \
codecs/mod_h26x \
codecs/mod_ilbc \
codecs/mod_isac \
codecs/mod_mp4v \
codecs/mod_opus \
codecs/mod_silk \
codecs/mod_siren \
codecs/mod_speex \
codecs/mod_theora \
asr_tts/mod_flite \
say/mod_say_en"
test ! -f  modules.conf || rm -f modules.conf
touch modules.conf
for i in $MODULES; do echo $i >> modules.conf; done
export VERBOSE=yes
export DESTDIR=%{buildroot}/
export PKG_CONFIG_PATH=/usr/bin/pkg-config:$PKG_CONFIG_PATH
export ACLOCAL_FLAGS="-I /usr/share/aclocal"

if test ! -f Makefile.in
then
   ./bootstrap.sh
fi

%configure -C \
--prefix=%{PREFIX} \
--exec-prefix=%{EXECPREFIX} \
--bindir=%{BINDIR} \
--sbindir=%{SBINDIR} \
--sysconfdir=%{SYSCONFDIR} \
--libexecdir=%{LIBEXECDIR} \
--sharedstatedir=%{SHARESTATEDIR} \
--localstatedir=%{LOCALSTATEDIR} \
--libdir=%{LIBDIR} \
--includedir=%{INCLUDEDIR} \
--datadir=%{DATADIR} \
--infodir=%{INFODIR} \
--mandir=%{MANDIR} \
--with-logfiledir=%{LOGFILEDIR} \
--with-modinstdir=%{MODINSTDIR} \
--with-rundir=%{RUNDIR} \
--with-dbdir=%{DBDIR} \
--with-htdocsdir=%{HTDOCSDIR} \
--with-soundsdir=%{SOUNDSDIR} \
--enable-core-libedit-support \
--with-grammardir=%{GRAMMARDIR} \
--with-scriptdir=%{SCRIPTDIR} \
--with-recordingsdir=%{RECORDINGSDIR} \
--with-pkgconfigdir=%{PKGCONFIGDIR} \
--with-erlang \
--with-openssl \
--disable-dependency-tracking \
%{?configure_options}

unset MODULES

%{__make}

######################################################################################################################
# Install it to the build root
######################################################################################################################
%install

%{__rm} -rf %{buildroot}
%{__make} DESTDIR=%{buildroot} install
rm -rf %{buildroot}/%{_sysconfdir}/kazoo

######################################################################################################################
# Include a script to add a freeswitch user with group daemon when the core RPM is installed
######################################################################################################################
%pre
%ifos linux
if ! /usr/bin/id freeswitch &>/dev/null; then
       /usr/sbin/useradd -r -g daemon -s /bin/false -c "The FreeSWITCH Open Source Voice Platform" -d %{HOMEDIR} freeswitch || \
                %logmsg "Unexpected error adding user \"freeswitch\". Aborting installation."
fi
%endif

%post
%{?run_ldconfig:%run_ldconfig}
# Make FHS2.0 happy
# %{__mkdir} -p /etc/opt

chown freeswitch:daemon /var/log/freeswitch /var/run/freeswitch

chkconfig --add freeswitch

######################################################################################################################
# When the core RPM is uninstalled remove the freeswitch user
######################################################################################################################
%postun
%{?run_ldconfig:%run_ldconfig}
if [ $1 -eq 0 ]; then
    userdel freeswitch || %logmsg "User \"freeswitch\" could not be deleted."
fi

######################################################################################################################
# List of files/directories to include in the core FreeSWITCH RPM
######################################################################################################################
%files                                                                                                                                                                                                                                                                                             
%defattr(-,freeswitch,daemon)
#################################### Basic Directory Structure #######################################################
%dir %attr(0750, freeswitch, daemon) %{LOCALSTATEDIR}
%dir %attr(0750, freeswitch, daemon) %{DBDIR}
%dir %attr(0750, freeswitch, daemon) %{GRAMMARDIR}
%dir %attr(0750, freeswitch, daemon) %{HTDOCSDIR}
%dir %attr(0750, freeswitch, daemon) %{LOGFILEDIR}
%dir %attr(0750, freeswitch, daemon) %{RUNDIR}
%dir %attr(0750, freeswitch, daemon) %{SCRIPTDIR}

#################################### Grammar Directory Structure #####################################################
%dir %attr(0750, freeswitch, daemon) %{GRAMMARDIR}/model
%dir %attr(0750, freeswitch, daemon) %{GRAMMARDIR}/model/communicator
%ifos linux
%dir %attr(0750, root, root) /etc/monit.d
%endif

#################################### FreeSWITCH Core Binaries ########################################################
%attr(0755, freeswitch, daemon) %{PREFIX}/bin/*
%{LIBDIR}/libfreeswitch*.so*
%{MODINSTDIR}/mod_console.so*
%{MODINSTDIR}/mod_logfile.so*
%{MODINSTDIR}/mod_syslog.so*
%{MODINSTDIR}/mod_dialplan_directory.so* 
%{MODINSTDIR}/mod_dialplan_xml.so* 
%{MODINSTDIR}/mod_commands.so*
%{MODINSTDIR}/mod_dptools.so*
%{MODINSTDIR}/mod_spandsp.so*
%{MODINSTDIR}/mod_loopback.so*
%{MODINSTDIR}/mod_sofia.so*
%{MODINSTDIR}/mod_event_socket.so*
%{MODINSTDIR}/mod_sndfile.so*
%{MODINSTDIR}/mod_tone_stream.so*
%{MODINSTDIR}/mod_conference.so*
%{MODINSTDIR}/mod_http_cache.so*
%{MODINSTDIR}/mod_channel_move.so*
%{MODINSTDIR}/mod_kazoo.so*
%{MODINSTDIR}/mod_local_stream.so*
%{MODINSTDIR}/mod_amr.so*
%{MODINSTDIR}/mod_amrwb.so*
%{MODINSTDIR}/mod_bv.so*
%{MODINSTDIR}/mod_celt.so*
%{MODINSTDIR}/mod_codec2.so*
%{MODINSTDIR}/mod_g723_1.so*
%{MODINSTDIR}/mod_g729.so*
%{MODINSTDIR}/mod_h26x.so*
%{MODINSTDIR}/mod_ilbc.so*
%{MODINSTDIR}/mod_isac.so*
%{MODINSTDIR}/mod_mp4v.so*
%{MODINSTDIR}/mod_opus.so*
%{MODINSTDIR}/mod_silk.so*
%{MODINSTDIR}/mod_siren.so*
%{MODINSTDIR}/mod_speex.so*
%{MODINSTDIR}/mod_theora.so*
%{MODINSTDIR}/mod_shout.so*
%{MODINSTDIR}/mod_flite.so*
%{MODINSTDIR}/mod_say_en.so*

#################################### Additional Files ################################################################
#%config(noreplace) %attr(0640, freeswitch, daemon) %{HTDOCSDIR}/*
%ifos linux
/etc/rc.d/init.d/freeswitch
%config(noreplace) /etc/sysconfig/freeswitch
%config(noreplace) %attr(0644, freeswitch, daemon) /etc/monit.d/freeswitch.monitrc
%if 0%{?suse_version} > 100
/usr/sbin/rcfreeswitch
%endif
%endif

######################################################################################################################                                                                                                                                                                             
# Developer Pacakge
######################################################################################################################
%package devel
Summary:        Development package for FreeSWITCH open source telephony platform
Group:          System/Libraries
Requires:       %{name} = %{version}-%{release}

%description devel
FreeSWITCH development files

%files devel
%defattr(-, freeswitch, daemon)
%{LIBDIR}/*.a
%{LIBDIR}/*.la
%{PKGCONFIGDIR}/*
#%{MODINSTDIR}/*.a
%{MODINSTDIR}/*.la
%{INCLUDEDIR}/*.h

######################################################################################################################                                                                                                                                                                             
# Clean the build environment
######################################################################################################################
%clean
%{__rm} -rf %{buildroot}

