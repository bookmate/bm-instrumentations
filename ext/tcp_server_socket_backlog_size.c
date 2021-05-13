#include "ruby.h"
#include "extconf.h"

#if __linux__

#include <errno.h>
#include <stdbool.h>

#include <sys/socket.h>
#include <netinet/tcp.h>
#include <netinet/in.h>

VALUE socket_backlog_size(VALUE tcp_server, bool raise) __attribute__ ((visibility ("hidden") ));

VALUE socket_backlog_size(VALUE tcp_server, bool raise) {
  int fd = NUM2INT(rb_funcall(tcp_server, rb_intern("to_i"), 0));
 	socklen_t tis = sizeof(struct tcp_info);
 	struct tcp_info ti;

  int err = getsockopt(fd, IPPROTO_TCP, TCP_INFO, &ti, &tis);

  if (err && raise) {
    rb_syserr_fail(errno, "getsockopt");
  }

  if (err) {
    return Qnil;
  }

  VALUE hash = rb_hash_new();
  rb_hash_aset(hash, ID2SYM(rb_intern("backlog_size")), INT2FIX(ti.tcpi_unacked));
  rb_hash_aset(hash, ID2SYM(rb_intern("backlog_max_size")), INT2FIX(ti.tcpi_sacked));

  return hash;
}

VALUE rb_tcp_server_socket_backlog_size(VALUE self) {
  return socket_backlog_size(self, true);
}

VALUE rb_tcp_server_try_socket_backlog_size(VALUE self) {
  return socket_backlog_size(self, false);
}

#endif

void Init_tcp_server_socket_backlog_size() {
#if __linux__
  VALUE tcp_server = rb_const_get(rb_cObject, rb_intern("TCPServer"));
  rb_define_method(tcp_server, "socket_backlog_size", rb_tcp_server_try_socket_backlog_size, 0);
  rb_define_method(tcp_server, "socket_backlog_size!", rb_tcp_server_socket_backlog_size, 0);
#endif
}
