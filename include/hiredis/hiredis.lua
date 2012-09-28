include "stdio"
include "sys/time"

ffi.cdef [[
typedef struct redisReply {
    int type;
    long long integer;
    int len;
    char *str;
    size_t elements;
    struct redisReply **element;
} redisReply;
typedef struct redisReadTask {
    int type;
    int elements;
    int idx;
    void *obj;
    struct redisReadTask *parent;
    void *privdata;
} redisReadTask;
typedef struct redisReplyObjectFunctions {
    void *(*createString)(const redisReadTask*, char*, size_t);
    void *(*createArray)(const redisReadTask*, int);
    void *(*createInteger)(const redisReadTask*, long long);
    void *(*createNil)(const redisReadTask*);
    void (*freeObject)(void*);
} redisReplyObjectFunctions;
typedef struct redisReader {
    int err;
    char errstr[128];
    char *buf;
    size_t pos;
    size_t len;
    size_t maxbuf;
    redisReadTask rstack[9];
    int ridx;
    void *reply;
    redisReplyObjectFunctions *fn;
    void *privdata;
} redisReader;
redisReader *redisReaderCreate(void);
void redisReaderFree(redisReader *r);
int redisReaderFeed(redisReader *r, const char *buf, size_t len);
int redisReaderGetReply(redisReader *r, void **reply);
void freeReplyObject(void *reply);
int redisvFormatCommand(char **target, const char *format, va_list ap);
int redisFormatCommand(char **target, const char *format, ...);
int redisFormatCommandArgv(char **target, int argc, const char **argv, const size_t *argvlen);
typedef struct redisContext {
    int err;
    char errstr[128];
    int fd;
    int flags;
    char *obuf;
    redisReader *reader;
} redisContext;
redisContext *redisConnect(const char *ip, int port);
redisContext *redisConnectWithTimeout(const char *ip, int port, struct timeval tv);
redisContext *redisConnectNonBlock(const char *ip, int port);
redisContext *redisConnectUnix(const char *path);
redisContext *redisConnectUnixWithTimeout(const char *path, struct timeval tv);
redisContext *redisConnectUnixNonBlock(const char *path);
int redisSetTimeout(redisContext *c, struct timeval tv);
void redisFree(redisContext *c);
int redisBufferRead(redisContext *c);
int redisBufferWrite(redisContext *c, int *done);
int redisGetReply(redisContext *c, void **reply);
int redisGetReplyFromReader(redisContext *c, void **reply);
int redisvAppendCommand(redisContext *c, const char *format, va_list ap);
int redisAppendCommand(redisContext *c, const char *format, ...);
int redisAppendCommandArgv(redisContext *c, int argc, const char **argv, const size_t *argvlen);
void *redisvCommand(redisContext *c, const char *format, va_list ap);
void *redisCommand(redisContext *c, const char *format, ...);
void *redisCommandArgv(redisContext *c, int argc, const char **argv, const size_t *argvlen);
]]

HIREDIS_MAJOR        =  0
HIREDIS_MINOR        =  11
HIREDIS_PATCH        =  0
REDIS_ERR            =  -1
REDIS_OK             =  0
REDIS_ERR_IO         =  1 -- Error in read or write
REDIS_ERR_EOF        =  3 -- End of file
REDIS_ERR_PROTOCOL   =  4 -- Protocol error
REDIS_ERR_OOM        =  5 -- Out of memory
REDIS_ERR_OTHER      =  2 -- Everything else...
REDIS_BLOCK          =  0x1
REDIS_CONNECTED      =  0x2
REDIS_DISCONNECTING  =  0x4
REDIS_FREEING        =  0x8
REDIS_IN_CALLBACK    =  0x10
REDIS_SUBSCRIBED     =  0x20
REDIS_MONITORING     =  0x40
REDIS_REPLY_STRING   =  1
REDIS_REPLY_ARRAY    =  2
REDIS_REPLY_INTEGER  =  3
REDIS_REPLY_NIL      =  4
REDIS_REPLY_STATUS   =  5
REDIS_REPLY_ERROR    =  6
REDIS_READER_MAX_BUF =  (1024*16)  -- Default max unused reader buffer.
