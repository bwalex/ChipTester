#include <sys/types.h>
#include <stdlib.h>
#include <string.h>

#include <jansson.h>
#include <curl/curl.h>

#include "http_json.h"


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


static CURL *curl;
int net_err = 0;


int
http_begin(void)
{
	curl_global_init(CURL_GLOBAL_ALL);
	if ((curl = curl_easy_init()) == NULL) {
		fprintf(stderr, "Curl error\n");
		return -1;
	}

	return 0;
}

void
http_end(void)
{
	curl_easy_cleanup(curl);
	curl_global_cleanup();
}


static
int
req(const char *url, int method, const char *ctype,
    const char *data, size_t data_len,
    char *dest, size_t bufsz, size_t *sz)
{
	CURLcode status;
	long code;
	int ret = 0;
	struct write_data wd;
	struct read_data rd;
	struct curl_slist *slist = NULL;
	char buf[256];


	curl_easy_reset(curl);

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

		snprintf(buf, sizeof(buf), "Content-Length: %d", (int)data_len);
		slist = curl_slist_append(slist, buf);

		curl_easy_setopt(curl, CURLOPT_READFUNCTION, _readdata);
		curl_easy_setopt(curl, CURLOPT_READDATA, &rd);
	}

	if (method == METHOD_POST) {
		curl_easy_setopt(curl, CURLOPT_POST, (method == METHOD_POST));
		//curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
		//curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)data_len);
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
		net_err = 1;
		ret = 1;
		goto out;
	}

	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &code);
	if (code != 200) {
		ret = (int)code;
		goto out;
	}

	*sz = (size_t)wd.pos;

out:

	return ret;
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


