#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <unistd.h>
#include <signal.h>
#include <jansson.h>

#include "http_json.h"


#define CACHE_SIZE	16

struct conn_cache_entry {
	int	active;
	int	fd;
	char	*host;
	int	port;
};


struct conn_cache_entry conn_cache[CACHE_SIZE];

static
int
conn_cache_get(const char *host, int port)
{
	int i;

	for (i = 0; i < CACHE_SIZE; i++) {
		if (!conn_cache[i].active)
			continue;

		if (conn_cache[i].port != port)
			continue;

		if (strcmp(conn_cache[i].host, host) != 0)
			continue;

		return conn_cache[i].fd;
	}

	return -1;
}


static
void
conn_cache_clear(int unused)
{
	int i;

	for (i = 0; i < CACHE_SIZE; i++) {
		if (!conn_cache[i].active)
			continue;
		close(conn_cache[i].fd);
		conn_cache[i].active = 0;
	}
}


int
http_begin(void)
{
	void *sh;

	sh = signal(SIGPIPE, conn_cache_clear);

	return (sh == SIG_ERR) ? -1 : 0;
}


void
http_end(void)
{
	conn_cache_clear(0);
}


static
void
cache_conn(const char *url, int port, int sock)
{
	int i;
	int found = 0;

	for (i = 0; i < CACHE_SIZE; i++) {
		if (!conn_cache[i].active) {
			found = 1;
			break;
		}
	}

	if (!found) {
		free(conn_cache[0].host);
		close(conn_cache[0].fd);
		i = 0;
	}

	conn_cache[i].port = port;
	conn_cache[i].host = strdup(url);
	conn_cache[i].fd = sock;
	conn_cache[i].active = 1;
}


static
int
http_cmd(int sock, const char *fmt, ...)
{
	va_list ap;
	size_t len;
	ssize_t ssz;
	char *msg;
	int rc = 0;

	va_start(ap, fmt);
	len = vasprintf(&msg, fmt, ap);
	va_end(ap);

	if (msg == NULL)
		return -1;

	ssz = send(sock, msg, len, 0);
	if (ssz < 0) {
		rc = -1;
		goto out;
	}

out:
	free(msg);
	return rc;
}

static
int
http_fetch(int sock, char *buf, size_t buf_len)
{
	char c;
	ssize_t ssz;
	int off = 0;

	do {
		ssz = read(sock, &c, 1);
		if (ssz < 0)
			return -1;
	        if (ssz == 0)
			break;
		buf[off++] = c;
		if ((size_t)off == buf_len)
			return -1;
	} while (c != '\n');

	if (buf[off-2] == '\r')
		buf[off-2] = '\0';
	else
		buf[off-1] = '\0';

	return 0;
}

static
int
req(const char *url_in, int method, const char *ctype,
    const char *data, size_t data_len,
    char *dest, size_t bufsz, size_t *sz)
{
	char buf[4096*1024];
	char url[1024];
	int off;
	int code;
	char *path;
	char *port_str;
	const char *method_str;
	char *p;
	struct hostent *he;
	struct sockaddr_in sin;
	struct timeval tv;
	int sock;
	int port = 80;
	int content_length;
	int val;
	int error;
	ssize_t ssz;

	url_in += strlen("http://");
	strcpy(url, url_in);
	if ((path = strchr(url, '/')) == NULL)
		return -1;

	*path++ = '\0';

	if ((port_str = strchr(url, ':')) != NULL) {
		*port_str++ = '\0';
		port = atoi(port_str);
	}

	conn_cache_clear(0);

	sock = conn_cache_get(url, port);
	if (sock < 0) {
		//printf("DEBUG: sock not cached\n");
		if ((he = gethostbyname(url)) == NULL) {
			perror("gethostbyname");
			return -1;
		}

		sock = socket(AF_INET, SOCK_STREAM, 0);
		if (sock < 0) {
			perror("socket");
			return -1;
		}

		memset(&tv, 0, sizeof(tv));
		tv.tv_sec = 30;
		val = 1;
		setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &val, sizeof(int));
		setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &val, sizeof(int));
		setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
		setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

		memset(&sin, 0, sizeof(sin));
		sin.sin_family = AF_INET;
		memcpy(&sin.sin_addr, he->h_addr, he->h_length);
		sin.sin_port = htons((short)port);

		error = connect(sock, (struct sockaddr *)&sin, sizeof(struct sockaddr));
		if (error) {
			perror("connect");
			return -1;
		}

		cache_conn(url, port, sock);
	}

        if (method == METHOD_POST)
		method_str = "POST";
	else if (method == METHOD_PUT)
		method_str = "PUT";
	else if (method == METHOD_PATCH)
		method_str = "PATCH";
	else if (method == METHOD_DELETE)
		method_str = "DELETE";
	else
		method_str = "GET";

	off = 0;
	off += (int)snprintf(buf + off, sizeof(buf)-off, "%s /%s HTTP/1.1\r\n", method_str, path);
	off += (int)snprintf(buf + off, sizeof(buf)-off, "Host: %s:%d\r\n", url, port);
	off += (int)snprintf(buf + off, sizeof(buf)-off, "Connection: Keep-Alive\r\n");
	off += (int)snprintf(buf + off, sizeof(buf)-off, "Accept: */*\r\n");
	off += (int)snprintf(buf + off, sizeof(buf)-off, "Content-Length: %d\r\n", (int)data_len);
	off += (int)snprintf(buf + off, sizeof(buf)-off, "Content-Type: %s\r\n\r\n", ctype);

	if ((int)data_len + off > sizeof(buf))
		return -1;

	if (data) {
		memcpy(buf + off, data, data_len);
		off += data_len;
	}

	ssz = send(sock, buf, off, 0);
	if (ssz < 0) {
		perror("send");
		return -1;
	}

	memset(buf, 0, sizeof(buf));
	printf("DEBUG: moo, all sent; waiting for receive now\n");

	content_length = 0;
	do {
		error = http_fetch(sock, buf, sizeof(buf));
		if (error) {
			fprintf(stderr, "buf: %s\n", buf);
			perror("http_fetch");
			return -1;
		}
		if ((strncmp(buf, "HTTP", 4)) == 0) {
			/* Status code line */
			p = strchr(buf, ' ');
			if (p == NULL)
				return -1;
			code = atoi(++p);
			if (code != 200)
				return code;
		} else if ((strncmp(buf, "Content-Length", strlen("Content-Length"))) == 0) {
			p = strchr(buf, ':');
			if (p == NULL)
				continue;
			++p;
			for (; *p != '\0' && (*p == ' ' || *p == '\t'); p++)
				;
			content_length = atoi(p);
		}
	} while (*buf != '\0');

	printf("DEBUG: moo, content_length: %d\n", (int)content_length);
	if (content_length > 0) {
		if ((size_t)content_length > bufsz)
			return -1;
		ssz = read(sock, dest, content_length);
		if (ssz < 0)
			return -1;
	}

	*sz = (size_t)content_length;

	return 0;
}


int
req_json(const char *url, int method, json_t *j_in, json_t **j_out)
{
	json_error_t j_err;
	char *data = '\0';
	char recv_buf[1024 * 1024]; /* 1 MB */
	int error;
	size_t bytes_recvd;
	size_t sz;

	if (j_in) {
		data = json_dumps(j_in, JSON_COMPACT);
		if (data == NULL)
			return -1;
	}

	sz = strlen(data);
	printf("DEBUG: Sending JSON (%d): %s\n\n", (int)sz, data);
	error = req(url, method, "application/json", data,
		    sz, recv_buf, sizeof(recv_buf),
		    &bytes_recvd);

	if (j_in)
		free(data);

	if (error)
		return error;

	if (j_out != NULL) {
		*j_out = json_loadb(recv_buf, bytes_recvd, 0, &j_err);
		if (*j_out == NULL) {
			/* XXX: make use of j_err */
			return -1;
		}
	}

	return 0;
}


#if 0
int
main(void)
{
	char url[1024];
	char recv_buf[1024 * 1024];
	char send_buf[1024 * 1024];
	int error;
	size_t bytes_recvd;


	printf("test main\n");

	snprintf(url, 1024, "http://127.0.0.1:4567/test");
	snprintf(send_buf, 1024*1024, "{'message':'hello'}");


	/* HTTP GET */
	error = req(url, METHOD_GET, NULL, NULL, 0, recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after GET\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("GET -> Received: %s\n", recv_buf);

	
	/* HTTP GET */
	error = req(url, METHOD_GET, NULL, NULL, 0, recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after GET\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("GET -> Received: %s\n", recv_buf);


	/* HTTP DELETE */
	error = req(url, METHOD_DELETE, NULL, NULL, 0, recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after DELETE\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("DELETE -> Received: %s\n", recv_buf);


	/* HTTP POST */
	error = req(url, METHOD_POST, "application/json", send_buf, strlen(send_buf), recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after POST\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("POST -> Received: %s\n", recv_buf);


	/* HTTP PUT */
	error = req(url, METHOD_PUT, "application/json", send_buf, strlen(send_buf), recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after PUT\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("PUT -> Received: %s\n", recv_buf);


	/* HTTP PATCH */
	error = req(url, METHOD_PATCH, "application/json", send_buf, strlen(send_buf), recv_buf, sizeof(recv_buf), &bytes_recvd);
	if (error != 0) {
		fprintf(stderr, "Bailing out after PATCH\n");
		exit(1);
	}

	recv_buf[bytes_recvd] = '\0';
	printf("PATCH -> Received: %s\n", recv_buf);


	return 0;
}
#endif
