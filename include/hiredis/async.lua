include "hiredis/hiredis"

ffi.cdef[[
struct redisAsyncContext;
struct dict;
typedef void (redisCallbackFn)(struct redisAsyncContext*, void*, void*);
typedef struct redisCallback {
    struct redisCallback *next;
    redisCallbackFn *fn;
    void *privdata;
} redisCallback;
typedef struct redisCallbackList {
    redisCallback *head, *tail;
} redisCallbackList;
typedef void (redisDisconnectCallback)(const struct redisAsyncContext*, int status);
typedef void (redisConnectCallback)(const struct redisAsyncContext*, int status);
typedef struct redisAsyncContext {
    redisContext c;
    int err;
    char *errstr;
    void *data;
    struct {
        void *data;
        void (*addRead)(void *privdata);
        void (*delRead)(void *privdata);
        void (*addWrite)(void *privdata);
        void (*delWrite)(void *privdata);
        void (*cleanup)(void *privdata);
    } ev;
    redisDisconnectCallback *onDisconnect;
    redisConnectCallback *onConnect;
    redisCallbackList replies;
    struct {
        redisCallbackList invalid;
        struct dict *channels;
        struct dict *patterns;
    } sub;
} redisAsyncContext;
redisAsyncContext *redisAsyncConnect(const char *ip, int port);
redisAsyncContext *redisAsyncConnectUnix(const char *path);
int redisAsyncSetConnectCallback(redisAsyncContext *ac, redisConnectCallback *fn);
int redisAsyncSetDisconnectCallback(redisAsyncContext *ac, redisDisconnectCallback *fn);
void redisAsyncDisconnect(redisAsyncContext *ac);
void redisAsyncFree(redisAsyncContext *ac);
void redisAsyncHandleRead(redisAsyncContext *ac);
void redisAsyncHandleWrite(redisAsyncContext *ac);
int redisvAsyncCommand(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, const char *format, va_list ap);
int redisAsyncCommand(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, const char *format, ...);
int redisAsyncCommandArgv(redisAsyncContext *ac, redisCallbackFn *fn, void *privdata, int argc, const char **argv, const size_t *argvlen);
]]
