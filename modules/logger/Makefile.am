loggerdir = $(pluginsdir)/logger

libconsole_logger_plugin_la_SOURCES = logger/console.c
libconsole_logger_plugin_la_CPPFLAGS = $(AM_CPPFLAGS)
libfile_logger_plugin_la_SOURCES = logger/file.c
libfile_logger_plugin_la_CPPFLAGS = $(AM_CPPFLAGS)
logger_LTLIBRARIES = libconsole_logger_plugin.la libfile_logger_plugin.la

libsyslog_plugin_la_SOURCES = logger/syslog.c
if HAVE_SYSLOG
if !HAVE_NACL # configure incorrectly thinks NaCl has this lib.
logger_LTLIBRARIES += libsyslog_plugin.la
endif
endif

libsd_journal_plugin_la_SOURCES = logger/journal.c
libsd_journal_plugin_la_CPPFLAGS = $(AM_CPPFLAGS) $(SYSTEMD_CFLAGS)
libsd_journal_plugin_la_LIBADD = $(SYSTEMD_LIBS)
if HAVE_SYSTEMD
logger_LTLIBRARIES += libsd_journal_plugin.la
endif

libandroid_logger_plugin_la_SOURCES = logger/android.c
libandroid_logger_plugin_la_CFLAGS = $(AM_CFLAGS)
libandroid_logger_plugin_la_LIBADD = -llog
if HAVE_ANDROID
logger_LTLIBRARIES += libandroid_logger_plugin.la
endif
