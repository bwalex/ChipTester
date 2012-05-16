#define METHOD_GET	0x00
#define METHOD_POST	0x01
#define METHOD_PUT	0x02
#define METHOD_PATCH	0x03
#define METHOD_DELETE	0x04

typedef size_t (*curl_readdata_t)(void *ptr, size_t size, size_t nmemb, void *priv);


struct read_data {
	const char *data;
	size_t total_sz;
	int pos;
};


int req_json(const char *url, int method, json_t *j_in, json_t **j_out);
int http_begin(void);
void http_end(void);
int req(const char *url, int method, const char *ctype,
	const char *data, size_t data_len, curl_readdata_t rd_fn,
	char *dest, size_t bufsz, size_t *sz);
