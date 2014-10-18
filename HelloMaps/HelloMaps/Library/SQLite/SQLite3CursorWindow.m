//
//  SQLite3CursorWindow.m
//  iAround
//
//  Created by d.tuhtamanov on 3/8/12.
//
//

#import "SQLite3CursorWindow.h"

@implementation SQLite3CursorWindow

@synthesize startPosition, size;
@dynamic count;

#pragma mark - Class life cycle
- (id)initWithWindowSize:(NSUInteger)windowSize
{
    self = [super init];
    if (self) {
        size = windowSize;
        startPosition = 0;
        window = [[NSMutableArray alloc] initWithCapacity:windowSize];
    }
    return self;
}

- (void)dealloc
{
    window = nil;
}

#pragma mark - Public methods
- (void)addItem:(NSMutableDictionary *)item
{
    if (window.count + 1 <= size) {
        [window addObject:item];
    }
}

- (NSMutableDictionary *)itemAtIndex:(NSInteger)index
{
    NSInteger indexInWindow = index - startPosition;
    if (indexInWindow < window.count) {
        return [window objectAtIndex:indexInWindow];
    } else {
        return nil;
    }
}

- (void)clear
{
    [window removeAllObjects];
}

- (NSUInteger)getCount
{
    return window.count;
}

- (BOOL)containsItemWithIndex:(NSInteger)index
{
    return index >= startPosition && index < (startPosition + [self getCount]);
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@", window];
}

@end
