#define METHOD_GET	0x00
#define METHOD_POST	0x01
#define METHOD_PUT	0x02
#define METHOD_PATCH	0x03
#define METHOD_DELETE	0x04

int req_json(const char *url, int method, json_t *j_in, json_t **j_out);
int http_begin(void);
void http_end(void);
