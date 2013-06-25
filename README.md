Purpose
--------------

LayerSprites is a library designed to simplify the use of sprite sheets (image maps containing multiple sub-images) in UIKit applications without using OpenGL or 3rd-party game libraries.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 6.1 / Mac OS 10.8 (Xcode 4.6.2, Apple LLVM compiler 4.2)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

LayerSprites requires ARC. If you wish to use LayerSprites in a non-ARC project, just add the -fobjc-arc compiler flag to all of the LayerSprites class files. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click each of the LayerSprites-related .m files in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in each of the LayerSprites-related .m files, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including all of the LayerSprites files) are checked.


Installation
---------------

To use LayerSprites, just drag the class files into your project and add the QuartzCore framework.


Classes
---------------

The LayerSprites library currently includes the following classes:

- LSImage - this is a class for representing an image file with associated clipping and transform data. It supports all the same image formats as UIImage, and most of the same methods.

- LSImageMap - this is a class for loading image maps, also known as image atlases or spritemaps.


LSImage properties
-------------------

The LSImage class has the following properties:

	@property (nonatomic, readonly) CGSize size;
	
The size of the image, in points. As with UIImage, on a retina display device the actual pixel dimensions may be twice the size, depending on the scale property.
	
	@property (nonatomic, readonly) CGFloat scale;

The image scale. For @2x images on Retina display devices this will have a value of 2.0.

    @property (nonatomic, readonly) CGRect contentsRect;

The clipping rectangle used to crop and resize the original image to fit the LSImage size. This rect is measured in unit coordinates, so for images that are not clipped, the contentsRect size will be {0, 0, 1, 1}.

    @property (nonatomic, readonly) CGPoint anchorPoint;

The center point used to position the sprite, measure in unit coordinates relative to the sprite bounds. Typically this will be {0.5, 0.5}, but if the sprite has been clipped then the value will be adjusted to compensate.

    @property (nonatomic, readonly) CGAffineTransform transform;

A transform that should be applied to the image when it is displayed. Typically this will either be the identity transform or a 90 degree rotation, used when the sprite has been rotated to fit inside an image map.

    @property (nonatomic, readonly) CGImageRef CGImage;
    
The underlying CGImage used by the LSImage. You can use this to draw the image into a CGContext, or set the contents property of a CALayer directly (instead of using the setContentsWithLSImage: category method.


LSImage methods
------------------

The LSImage class has the following methods:

	+ (LSImage *)imageWithUIImage:(UIImage *)image
                     contentsRect:(CGRect)contentsRect
                      anchorPoint:(CGPoint)anchorPoint
                          rotated:(BOOL)rotated;

    - (LSImage *)initWithUIImage:(UIImage *)image
                    contentsRect:(CGRect)contentsRect
                     anchorPoint:(CGPoint)anchorPoint
                         rotated:(BOOL)rotated;
                         
These methods create an LSImage with the specified contentsRect, anchorPoint and an optional rotation by 90 degrees. This is useful when manually creating sprites from an existing image. Note that the LSImage retains the original source image but does not duplicate it.

    - (void)drawAtPoint:(CGPoint)point;
    
This method draws the image at the specified point with the correct clipping and orientation applied. Unlike the equivalent UIImage, this method will draw the sprite image centered on the point instead of descending down and leftwards from it. The centering will depend on the anchorPoint, and may not be the actual center of the image.
    
    - (void)drawInRect:(CGRect)rect;

This method draws the image inside the specified rect with the correct clipping and orientation applied. Note that if the rect's aspect ratio does not match that of the size property, the image will appear stretched. The anchorPoint and size are ignored.

    - (CGRect)rectWhenDrawnAtPoint:(CGPoint)point;

This method returns the bounding rect of the image when drawn at the specified point. Passing the result of this method to the `drawInRect:` method is equivalent to calling `drawAtPoint:` with the same point.


CALayer extension methods
-----------------------------

LSImage extends CALayer with the following method:

    - (void)setContentsWithLSImage:(LSImage *)image;

This method sets the layer contents image and associated attributes (contentsRect, contentsScale, affineTransform} needed to display the LSImage correctly. This method does not set the anchorPoint or layer bounds.

    - (void)setDimensionsWithLSImage:(LSImage *)image;
    
This method sets the bounds and anchorPoint for the sprite. This is not neccesary if the sprite has not been trimmed, but is required to display the sprite correctly if it has been trimmed from its original size.


LSImageMap methods
----------------------

The LSImageMap class has the following methods:

    + (LSImageMap *)imageMapWithContentsOfFile:(NSString *)nameOrPath;
    - (LSImageMap *)initWithContentsOfFile:(NSString *)nameOrPath;
    
These methods are used to create a LSImageMap from a file. The parameter can be an absolute or relative file path (relative paths are assumed to be inside the application bundle). If the file extension is omitted it is assumed to be .plist. Currently the only image map file format that is supported is the Cocos2D sprite map format, which can be exported by tools such as Zwoptex or TexturePacker. LSImageMap fully supports rotated and trimmed images, as well as image aliases. It will automatically detect @2x Retina imagemap files and files with the ~ipad suffix.

    + (LSImageMap *)imageMapWithUIImage:(UIImage *)image data:(NSData *)data;    
    - (LSImageMap *)initWithUIImage:(UIImage *)image data:(NSData *)data;
    
These methods are used to create a LSImageMap from data. The data should represent the contents of an image map file in one of the formats supported by the `imageMapWithContentsOfFile:` method. If the image argument is nil, LSImageMap will attempt to locate the image file from the filename specified in the data, however if the image file is not located in the root of the application bundle, it may not be able to find it. In this case, you can supply a UIImage to be used as the image map image and the image file specified in the data will be ignored.
    
    - (NSInteger)imageCount;
    
This method returns the number of images in the image map.
    
    - (NSString *)imageNameAtIndex:(NSInteger)index;
    
This method returns the image name at the specified index. Image names are sorted alphabetically, and do not neccesarily reflect the order in which they appear in the sprite sheet file.
    
    - (LSImage *)imageAtIndex:(NSInteger)index;
    - (LSImage *)objectAtIndexedSubscript:(NSInteger)index;
    
These methods return the image map image at the specified index. Both methods behave the same way, but the second is included to support object subscripting, allowing the sprite to be accessed using the `spritemap[index]` syntax. Image map images are sorted alphabetically, and do not neccesarily reflect the order in which they appear in the sprite sheet file. If you wish to access the images in a specific order, it is a good idea to name them numerically, padded to the same length with zeros.
    
    - (LSImage *)imageNamed:(NSString *)name;
    - (LSImage *)objectForKeyedSubscript:(NSString *)name;
    
These methods return the image map image with the specified name. Both methods behave the same way, but the second is included to support object subscripting, allowing the sprite to be accessed using the `spritemap[@"spriteName"]` syntax. Depending on the tool used to generate the image map data file, the name may include a file extension. If you do not include a file extension in the name parameter, png is assumed.


Fast enumeration
--------------------

LSImageMap supports fast enumeration, so you can easily iterate through the sprites in your map using the following syntax:

    LSImageMap *imageMap = [LSImageMap imageMapWithContentsOfFile:@"foo.plist"];
    for (NSString *name in imageMap)
    {
        LSImageSprite *sprite = imageMap[name];
        //do something with sprite
    }


Using image sprites with CALayer
----------------------------------

There are a number of ways to display sprite image loaded using LayerSprites. The typical approach will be to display the image inside a CALayer. To do that, use the following code:

    //create layer
    CALayer *layer = [CALLayer layer];

    //set sprite image and dimensions
    [layer setContentsWithLSImage:image];
    [layer setDimensionsWithLSImage:image];
    
    //set position and add to screen
    layer.position = CGPointMake(..., ...)
    [someView.layer addSublayer:layer];

Check the LayersDemo for an example of this in action. If you are updating the image fror a sprite that has already been added to the screen, you will probably want to disable implicit animations, like this:

    //disable animation
    [CATransaction transaction];
    [CATransaction setDisableActions:YES];
    
    //set sprite image and dimensions
    [layer setContentsWithLSImage:image];
    [layer setDimensionsWithLSImage:image];
    
    //re-enable animation
    [CATransaction commit]; 
    
The CATransaction code is needed to disable implicit animations when setting the layer contents and other attributes. It is possible to set many sprites within the same transaction, which is why the transaction code is not included in the setter methods. It is possible to disable implicit animations in other ways, such as by specifying a custom actions dictionary. You don't have to disable animations, but the default animation effect of switching between sprites probably isn't what you'd expect.

Note 1: Because the `setContentsWithLSImage:` method sets the affineTransform of the layer, you will need to re-apply any transform/affineTransform to the layer after setting the sprite. Make sure to preserve the existing transform or the sprite may be oriented incorrectly. You can do that like this:

    //create a new transform
    CATransform3D transform = //some transform
    
    //set sprite transform without affecting sprite orientation
    layer.transform = CATransform3DConcat(layer.transform, transform);
    
Note 2: It does not seem to be possible to use the `setDimensionsWithLSImage:` method reliably with view backing layers if the sprite has been trimmed and rotated. Backing layers do not rotate correctly when the anchorPoint is not exactly {0.5, 0.5}. If you wish to place sprites inside views, either use a nested sublayer or disable trimming and/or rotation when exporting the sprite sheet.


Using image sprites with UIKit/Core Graphics
---------------------------------------------

Although setting the sprite as a CALayer's contents yields the best performance and memory usage, you can also draw sprites directly into a CGContext using `drawAtPoint:` or `drawInRect:` methods. See the DrawingDemo for an example.