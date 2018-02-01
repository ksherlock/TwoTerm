//
//  ChildMonitor.m
//  TwoTerm
//
//  Created by Kelvin Sherlock on 1/31/2018.
//

#import "ChildMonitor.h"
#import "TermWindowController.h"

#include "Lock.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#include <vector>
#include <algorithm>


namespace  {

    struct entry {
        pid_t pid;
        int fd;
        TermWindowController *controller;
    };

    
    typedef std::vector<entry> entry_vector;
    
    entry_vector::iterator find_controller(entry_vector &table, TermWindowController *controller) {
        return std::find_if(table.begin(), table.end(), [=](const entry &e){
            return e.controller == controller;
        });
    }

    entry_vector::iterator find_pid(entry_vector &table, pid_t pid) {
        return std::find_if(table.begin(), table.end(), [=](const entry &e){
            return e.pid == pid;
        });
    }

    entry_vector::iterator find_fd(entry_vector &table, int fd) {
        return std::find_if(table.begin(), table.end(), [=](const entry &e){
            return e.fd == fd;
        });
    }
    
    /* return NO on EOF */
    BOOL read(int fd, TermWindowController *controller) {
        size_t total = 0;
        for (;;) {
            uint8_t buffer[2048];
            ssize_t ok = ::read(fd, buffer, sizeof(buffer));
            if (ok == 0) return total > 0;
            if (ok < 1) {
                if (errno == EINTR) continue;
                if (errno == EAGAIN) return YES;
                return YES;
            }
            [controller processData: buffer size: ok];
            if (ok < sizeof(buffer)) return YES;
            total += ok;
        }
    }
    
}


@interface ChildMonitor() {
    std::vector<entry> _table;
    int _kq;
    Lock _lock;
}
@end
@implementation ChildMonitor

+(id)monitor {
    static ChildMonitor *me = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        me = [ChildMonitor new];
        [NSThread detachNewThreadSelector: @selector(run) toTarget: me withObject: nil];
    });
    return me;
}

-(id)init {
    if ((self = [super init])) {
        
        _kq = kqueue();
        
    }
    return self;
}

-(void)dealloc {
    _lock.lock();
    close(_kq);
    for (const auto &e : _table) {
        if (e.fd >= 0) close(e.fd);
        if (e.pid > 0) kill(e.pid, SIGHUP);
        if (e.controller) [e.controller release];
    }
    _lock.unlock();
    [super dealloc];
}

-(void)removeController: (TermWindowController *)controller {

    if (!controller) return;
    
    Locker l(_lock);

    auto iter = find_controller(_table, controller);
    if (iter != _table.end()) {
        [iter->controller release];
        iter->controller = nil;
        if (iter->pid > 0) kill(iter->pid, SIGHUP);
    }
}

-(void)addController: (TermWindowController *)controller pid: (pid_t)pid fd: (int)fd {

    NSLog(@"Adding pid: %d fd: %d", pid, fd);

    int flags;
    // non-blocking io.
    if (fcntl(fd, F_GETFL, &flags) < 0) flags = 0;
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    
    Locker l(_lock);
    
    _table.emplace_back(entry{pid, fd, [controller retain]});

    struct kevent events[2] = {};
    
    EV_SET(&events[0], fd, EVFILT_READ, EV_ADD | EV_RECEIPT, 0, 0, NULL);
    EV_SET(&events[1], pid, EVFILT_PROC, EV_ADD | EV_ONESHOT | EV_RECEIPT, NOTE_EXIT | NOTE_EXITSTATUS, 0, NULL);
    
    kevent(_kq, events, 2, NULL, 0, NULL);
}

-(void) run {
    struct kevent events[16] = {};

    for(;;) {

        @autoreleasepool {

            int n = kevent(_kq, NULL, 0, events, 2, NULL);
            
            if (n < 0) {
                NSLog(@"kevent: %s", strerror(errno));
                continue;
            }
            if (n == 0) {
                continue;
            }
            Locker l(_lock);

            // should process twice, first for reading, second for dead children.
            
            std::for_each(events, events +  n, [&](const struct kevent &e){
                
                if (e.filter != EVFILT_READ) return;
                int fd = (int)e.ident;
                if (e.flags & EV_EOF) {
                    NSLog(@"EV_EOF %d", fd);
                    return;
                }
                
                if (e.flags & EV_ERROR) {
                    NSLog(@"EV_ERROR %d", fd);
                    return;
                }
                
                auto iter = find_fd(_table, fd);
                if (iter == _table.end() || iter->controller == nil) {
                    
                    NSLog(@"Closing fd %d (not found)", fd);
                    close(fd); // should automatically remove itself from kevent
                    iter->fd = -1;
                } else {
                    BOOL ok = read(fd, iter->controller);
                    if (!ok) {
                        NSLog(@"Closing fd %d (eof)", fd);
                        close(fd); // should automatically remove itself from kevent
                        iter->fd = -1;
                    }
                }
            });

            std::for_each(events, events +  n, [&](const struct kevent &e){
                
                if (e.filter != EVFILT_PROC) return;
                
                pid_t pid = (pid_t)e.ident;

                int status = 0;
                for(;;) {
                    int ok = waitpid(pid, &status, WNOHANG);
                    if (ok >= 0) break;
                    if (errno == EINTR) continue;
                    NSLog(@"waitpid(%d): %s", pid, strerror(errno));
                    break;
                }
                
                
                auto iter = find_pid(_table, pid);
                if (iter == _table.end()) {
                    
                } else {
                    if (iter->fd >= 0) {

                        // check for pending i/o ?

                        if (iter->controller)
                            read(iter->fd, iter->controller);
                        NSLog(@"Closing fd %d (child exited)", iter->fd);
                        close(iter->fd);
                        iter->fd = -1;
                    }
                    [iter->controller childFinished: status];

                    [iter->controller release];
                    iter->controller = nil;
                    *iter = std::move(_table.back());
                    _table.pop_back();
                }
                
                NSLog(@"Child %d finished", pid);
            });
        }
    }
}

@end
