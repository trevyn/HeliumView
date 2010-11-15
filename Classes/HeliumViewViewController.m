//
//  HeliumViewViewController.m
//  HeliumView
//
//  Created by Eden on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HeliumViewViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation HeliumViewViewController


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	//[tileLayer setNeedsDisplay];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	
	return outerView;
	
}

- (NSData *)loadDataWithCacheFromFilename:(NSString *)theFilename {
	
	// try to load from Documents

//	NSString *docDir= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
//	NSString *filePath= [docDir stringByAppendingPathComponent:theFilename];
	NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:theFilename];

	NSData *theData= [NSData dataWithContentsOfFile:filePath];

	// if no file, fetch and write

	if(!theData) {
		NSString *fileUrl= [NSString stringWithFormat:@"http://10.0.1.3:8000/%@", theFilename];
		theData= [NSData dataWithContentsOfURL:[NSURL URLWithString:fileUrl]];
		if(theData)
		   [theData writeToFile:filePath atomically:YES];
//		NSLog(@"fetch: %@: %d", fileUrl, [theData length]);
	}
	else {
//		NSLog(@"cached: %@: %d", filePath, [theData length]);
	}
	
	return theData;
}


CGImageRef CreateScaledCGImageFromCGImage(CGImageRef image, float scale)
{
	// Create the bitmap context
	CGContextRef    context = NULL;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	// Get image width, height. We'll use the entire image.
	int width = CGImageGetWidth(image) * scale;
	int height = CGImageGetHeight(image) * scale;
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow   = (width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL)
	{
		return nil;
	}
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
	context = CGBitmapContextCreate (bitmapData,width,height,8,bitmapBytesPerRow,
									 colorspace,kCGImageAlphaNoneSkipFirst);
	CGColorSpaceRelease(colorspace);
	
	if (context == NULL)
		// error creating context
		return nil;
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(context, CGRectMake(0,0,width, height), image);
	
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(bitmapData);
	
	return imgRef;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

	[CATransaction begin];
	[CATransaction setAnimationDuration:0.0];
	
	CGRect visibleRect;
	visibleRect.origin = scrollView.contentOffset;
	visibleRect.size = scrollView.bounds.size;
	
	double theScale = 1.0 / scrollView.zoomScale;
	visibleRect.origin.x *= theScale;
	visibleRect.origin.y *= theScale;
	visibleRect.size.width *= theScale;
	visibleRect.size.height *= theScale;
	
	double xPos= CGRectGetMidX(visibleRect);
	double yPos= CGRectGetMidY(visibleRect);

	double leastDist= 9999;
	CALayer *closestLayer;
	
	NSArray *sublayers= outerView.layer.sublayers;
	
	lastClosestLayer.opacity=0.05;
	lastClosestLayer.zPosition=-1;

	
	for(CALayer *element in sublayers) {
		double dist= sqrt(pow((element.position.x-xPos), 2.0)+pow((element.position.y-yPos), 2.0));
//		if(dist < 200) {
//			double opacity= dist/100;
//			 opacity= 1-opacity;
//			//if(opacity < 0.1)
//			//	opacity= 0.1;
//			opacity/= 6;
//			
//			[element setZPosition:-dist];
//			[element setOpacity:opacity];
//		}
		if(dist < leastDist) {
			leastDist= dist;
			closestLayer= element;
		}
	}
	
	lastClosestLayer= closestLayer;
	
	closestLayer.opacity= 1;
	closestLayer.zPosition= 1;
	
	[CATransaction commit];
	
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self performSelectorOnMainThread:@selector(doLoad) withObject:nil waitUntilDone:NO];
}	
	
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)doLoad {
 	// copy over sql and open it

//	[self loadDataWithCacheFromFilename:@"helium_snaps.sqlite"];
	
	sqlite= [[EPSqlite alloc] init];
	[sqlite	openDatabaseFromBundleWithFilename:@"snaps2.sqlite"];
	
	[self initZoom];
	
	scrollView.maximumZoomScale= 128.0f;
	scrollView.minimumZoomScale= 0.5f;
	scrollView.scrollEnabled = YES;
	scrollView.delegate= self;
 
	[self.view setBackgroundColor:[UIColor blackColor]];

	outerView= [[UIView alloc] initWithFrame:CGRectMake(0,0, 8000, 8000)];
	[scrollView addSubview:outerView];

	NSString *sqlString= @"SELECT picTimestamp,headTrue,posLatitude,posLongitude FROM snaps2 WHERE id > 300 and id < 700";
	
	sqlite3_stmt *compiledStatement;
	int snapNum= 0;
	if(sqlite3_prepare_v2([sqlite database], [sqlString UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			snapNum++;
			
			NSAutoreleasePool *pool;
			pool = [[NSAutoreleasePool alloc] init];

			const char *text= sqlite3_column_text(compiledStatement, 0);
			double myHeading= sqlite3_column_double(compiledStatement, 1);
			double myLat= sqlite3_column_double(compiledStatement, 2);
			double myLon= sqlite3_column_double(compiledStatement, 3);
			
			NSString *snapTimestamp= [NSString stringWithUTF8String:text];
			
			// make filename string
				
			NSLog(@"%f, %f", [self xFromLongitude:myLon], [self yFromLatitude:myLat]);
			
			NSString *fileName= [NSString stringWithFormat:@"snap-%@.jpg", snapTimestamp];
			
			NSData *theData= [self loadDataWithCacheFromFilename:fileName];
			
			if(!theData)
				continue;
			
			CGImageRef *theImage= [[UIImage imageWithData:theData] CGImage];
			
			CGImageRef *newImage= CreateScaledCGImageFromCGImage(theImage, 0.125);
			
			CALayer* aLayer = [CALayer layer];
			[aLayer	retain];
			//aLayer.rasterizationScale= 1.0;
			aLayer.opaque= NO;
			aLayer.shouldRasterize= NO;
			aLayer.opacity= 0.05;
			aLayer.zPosition=-1;
			
			UIImage* backgroundImage = [UIImage imageWithData:theData];
			CGFloat nativeWidth = CGImageGetWidth(backgroundImage.CGImage);
			CGFloat nativeHeight = CGImageGetHeight(backgroundImage.CGImage);
			CGRect  startFrame = CGRectMake([self xFromLongitude:myLon], [self yFromLatitude:myLat], nativeWidth/5, nativeHeight/5);
			//CGRect  startFrame = CGRectMake((snapNum%10)*(nativeWidth/10), (snapNum/10)*(nativeHeight/10), nativeWidth/10, nativeHeight/10);
			aLayer.frame = startFrame; 
			aLayer.transform = CATransform3DMakeRotation((myHeading+90)/57.2958, 0,0,1.0);
						
			aLayer.contents = (id)newImage; //backgroundImage.CGImage;
			
			[outerView.layer addSublayer: aLayer];
			
			[pool drain];
	
		}
	}
	
	sqlite3_finalize(compiledStatement);
	
	
	NSLog(@"done");

}


- (void)initZoom {
	
	minLongitude= [sqlite querySingleDouble:@"SELECT min(posLongitude) FROM snaps2 WHERE posLongitude"];
	maxLongitude= [sqlite querySingleDouble:@"SELECT max(posLongitude) FROM snaps2 WHERE posLongitude < -120"];
	minLatitude= [sqlite querySingleDouble:@"SELECT min(posLatitude) FROM snaps2 WHERE posLatitude"];
	maxLatitude= [sqlite querySingleDouble:@"SELECT max(posLatitude) FROM snaps2 WHERE posLatitude"];


	double longitudeDiff= maxLongitude-minLongitude;
	double latitudeDiff= maxLatitude-minLatitude;
	
	double longitudeScale= longitudeDiff/5000;  // fitting all longitude into 5000 would be this deg per pixel
	double latitudeScale= latitudeDiff/(5000/1.25);  // fitting all latitude into 5000 would be this deg per pixel, BUT! pretend like it's less because we just end up stretching it out
	
	scaleFactor= (longitudeScale > latitudeScale) ? longitudeScale : latitudeScale;
	//	zoomLevel= 1.0f;
}

- (double)xFromLongitude: (double)longitude {
	return ((longitude - minLongitude) / scaleFactor)+1000;
}

- (double)yFromLatitude: (double)latitude {
	return (((maxLatitude - latitude) / scaleFactor)*1.25)+1000;
}

- (double)longitudeFromX: (double)x {
	return (((x-1000) * scaleFactor) + minLongitude);
}

- (double)latitudeFromY: (double)y {
	//	return ((y * scaleFactor) / 1.25) + minLatitude;
	return (-((((y-1000) / 1.25) * scaleFactor) - maxLatitude));
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
