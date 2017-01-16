#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface Foo : NSObject
+ (Foo *)sharedInstance;
+ (id)someClassMethod;
- (id)someInstanceMethod;
@end

@interface OCMockThreadSafetyTests : XCTestCase
@end

@implementation OCMockThreadSafetyTests

// Repeatedly invokes +someClassMethod and -someInstanceMethod on a background thread.
+ (void)invokeMethodsRepeatedly {
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    [Foo someClassMethod];
    Foo * foo = [Foo sharedInstance];
    [foo someInstanceMethod];
    [self invokeMethodsRepeatedly];
  });
}

// Static setup starts background threads.
+ (void)setUp {
  [super setUp];
  [self invokeMethodsRepeatedly];
  NSLog(@"+%@", NSStringFromSelector(_cmd));
}

// Invokes the same test case 100 times.
- (void)invokeTest {
  static const int kRepeatCount = 100;
  for (int i = 1; i <= kRepeatCount; ++i) {
    NSLog(@"Invoking test %d of %d", i, kRepeatCount);
    [super invokeTest];
  }
}

- (void)setUp {
  [super setUp];
  NSLog(@"-%@", NSStringFromSelector(_cmd));
}

- (void)tearDown {
  NSLog(@"-%@", NSStringFromSelector(_cmd));
  [super tearDown];
}

// This test causes flakiness in v3 only.
- (void)testMockHandlesBackgroundInvocations {
  id mock = [OCMockObject mockForClass:[Foo class]];
  [[[mock stub] andReturn:@"mocked"] someInstanceMethod];
  NSLog(@"%@: %@", NSStringFromSelector(_cmd), mock);
}

@end

@implementation Foo

+ (Foo *)sharedInstance {
  NSLog(@"+sharedInstance (%@)", NSStringFromSelector(_cmd));
  static Foo *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[Foo alloc] init];
  });
  return instance;
}

+ (id)someClassMethod {
  NSLog(@"+someClassMethod (%@)", NSStringFromSelector(_cmd));
  return NSStringFromSelector(_cmd);
}

- (id)someInstanceMethod {
  NSLog(@"-someInstanceMethod(%@)", NSStringFromSelector(_cmd));
  return NSStringFromSelector(_cmd);
}

@end

