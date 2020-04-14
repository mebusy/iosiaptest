/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creates a category for the SKDownload class.
*/

#import "SKDownload+SKDownloadAdditions.h"

@implementation SKDownload (SKDownloadAdditions)
/// - returns: A string representation of the downloadable content length.
-(NSString *)downloadContentSize {
    return [NSByteCountFormatter stringFromByteCount:self.expectedContentLength countStyle:NSByteCountFormatterCountStyleFile];
}

@end
