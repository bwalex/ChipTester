#include <sys/types.h>
#include <stdlib.h>
#include <string.h>

#include <jansson.h>
#include <curl/curl.h>

#define METHOD_GET	0x00
#define METHOD_POST	0x01
#define METHOD_PUT	0x02
#define METHOD_PATCH	0x03
#define METHOD_DELETE	0x04


struct write_data {
	char *data;
	size_t maxsz;
	int pos;
};

struct read_data {
	const char *data;
	size_t total_sz;
	int pos;
};


static
size_t
_writedata(char *ptr, size_t size, size_t nmemb, void *priv)
{
	struct write_data *wd = priv;
	size_t wrsize = size*nmemb;

	if (wd->pos + wrsize >= wd->maxsz - 1) {
		fprintf(stderr, "out of buffer space\n");
		/* Returning a value != size*nmemb signals error */
		return 0;
	}

	memcpy(wd->data + wd->pos, ptr, wrsize);
	wd->pos += wrsize;

	return wrsize;
}


static
size_t
_readdata(void *ptr, size_t size, size_t nmemb, void *priv)
{
	struct read_data *rd = priv;
	size_t rdsize = size*nmemb;

	if (rd->total_sz < rdsize)
		rdsize = rd->total_sz;

	memcpy(ptr, rd->data + rd->pos, rdsize);
	rd->pos += rdsize;
	rd->total_sz -= rdsize;

	return rdsize;
}


static
int
req(const char *url, int method, const char *ctype,
    const char *data, size_t data_len,
    char *dest, size_t bufsz, size_t *sz)
{
	CURL *curl;
	CURLcode status;
	long code;
	int ret = 0;
	struct write_data wd;
	struct read_data rd;
	struct curl_slist *slist = NULL;
	char buf[256];


	if ((curl = curl_easy_init()) == NULL) {
		fprintf(stderr, "Curl error\n");
		return -1;
	}

	wd.data = dest;
	wd.maxsz = bufsz;
	wd.pos = 0;

	curl_easy_setopt(curl, CURLOPT_URL, url);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, _writedata);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &wd);

	if (method != METHOD_GET && data != NULL && data_len > 0) {
		rd.data = data;
		rd.total_sz = data_len;
		rd.pos = 0;

		snprintf(buf, sizeof(buf), "Content-Length: %ju", data_len);
		slist = curl_slist_append(slist, buf);

		curl_easy_setopt(curl, CURLOPT_READFUNCTION, _readdata);
		curl_easy_setopt(curl, CURLOPT_READDATA, &rd);
	}

	if (method == METHOD_POST) {
		curl_easy_setopt(curl, CURLOPT_POST, (method == METHOD_POST));
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, data_len);
	} else if (method == METHOD_PUT || method == METHOD_PATCH) {
		curl_easy_setopt(curl, CURLOPT_PUT, 1);
	}

	if (method != METHOD_GET && ctype != NULL) {
		snprintf(buf, sizeof(buf), "Content-Type: %s", ctype);
		slist = curl_slist_append(slist, buf);
	}

	if (method == METHOD_DELETE) {
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");
	} else if (method == METHOD_PATCH) {
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
	}

	if (slist != NULL) {
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);
	}

	status = curl_easy_perform(curl);

	if (slist != NULL)
		curl_slist_free_all(slist);

	if (status != 0) {
		fprintf(stderr, "curl err: %s\n", curl_easy_strerror(status));
		ret = 1;
		goto out;
	}

	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &code);
	if (code != 200) {
		fprintf(stderr, "Server error: %ld\n", code);
		ret = (int)code;
		goto out;
	}

	*sz = (size_t)wd.pos;

out:
	curl_easy_cleanup(curl);
	curl_global_cleanup();

	return ret;
}


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
