//
//  MCSceneController.m
//  MCGame
// 
//  Created by ruitaoCC@gmail.com on 1/09/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import "MCSceneController.h"
#import "MCInputViewController.h"
#import "EAGLView.h"
#import "MCSceneObject.h"
#import "MCConfiguration.h"
#import "MCPoint.h"
#import "TestCube.h"
@implementation MCSceneController

@synthesize inputController, openGLView;
@synthesize animationInterval, animationTimer;
@synthesize levelStartDate;
@synthesize deltaTime;

// Singleton accessor.  this is how you should ALWAYS get a reference
// to the scene controller.  Never init your own. 
+(MCSceneController*)sharedSceneController
{
  static MCSceneController *sharedSceneController;
  @synchronized(self)
  {
    if (!sharedSceneController)
      sharedSceneController = [[MCSceneController alloc] init];
	}
	return sharedSceneController;
}


#pragma mark scene preload
-(void)restartScene{
    // queue up all the old objects to be removed
	[objectsToRemove addObjectsFromArray:sceneObjects];
	// reload the scene
	needToLoadScene = YES;

}
// this is where we initialize all our scene objects
-(void)loadScene
{needToLoadScene = NO;
	RANDOM_SEED();
	// this is where we store all our objects
	if (sceneObjects == nil) sceneObjects = [[NSMutableArray alloc] init];	
	
	// our 'character' object
	TestCube * magicCube = [[TestCube alloc] init];
	magicCube.translation = MCPointMake(0.0, 0.0, 0.0);
	magicCube.scale = MCPointMake(30, 30, 30.0);
	[self addObjectToScene:magicCube];
	[magicCube release];	
    
	
	// if we do not have a collision controller, then make one and link it to our
	// sceneObjects
//	if (collisionController == nil) collisionController = [[MCCollisionController alloc] init];
//	collisionController.sceneObjects = sceneObjects;
//	if (DEBUG_DRAW_COLLIDERS)	[self addObjectToScene:collisionController];
    
	// reload our interface
	[inputController loadInterface];

    
}



// we dont actualy add the object directly to the scene.
// this can get called anytime during the game loop, so we want to
// queue up any objects that need adding and add them at the start of
// the next game loop
-(void)addObjectToScene:(MCSceneObject*)sceneObject
{
	if (objectsToAdd == nil) objectsToAdd = [[NSMutableArray alloc] init];
	sceneObject.active = YES;
	[sceneObject awake];
	[objectsToAdd addObject:sceneObject];
}

// similar to adding objects, we cannot just remove objects from
// the scene at any time.  we want to queue them for removal 
// and purge them at the end of the game loop
-(void)removeObjectFromScene:(MCSceneObject*)sceneObject
{
	if (objectsToRemove == nil) objectsToRemove = [[NSMutableArray alloc] init];
	[objectsToRemove addObject:sceneObject];
}


// makes everything go
-(void) startScene
{
	self.animationInterval = 1.0/MC_FPS;
	[self startAnimation];
	self.levelStartDate = [NSDate date];
	lastFrameStartTime = 0;
}

#pragma mark Game Loop

- (void)gameLoop
{
	// we use our own autorelease pool so that we can control when garbage gets collected
	NSAutoreleasePool * apool = [[NSAutoreleasePool alloc] init];
    
	thisFrameStartTime = [levelStartDate timeIntervalSinceNow];
	deltaTime =  lastFrameStartTime - thisFrameStartTime;
	lastFrameStartTime = thisFrameStartTime;
	
	
	
	// add any queued scene objects
	if ([objectsToAdd count] > 0) {
		[sceneObjects addObjectsFromArray:objectsToAdd];
		[objectsToAdd removeAllObjects];
	}
	
	// update our model
	[self updateModel];
	
    
    // deal with collisions
//	[collisionController handleCollisions];
    
	// send our objects to the renderer
	[self renderScene];
	
	// remove any objects that need removal
	if ([objectsToRemove count] > 0) {
		[sceneObjects removeObjectsInArray:objectsToRemove];
		[objectsToRemove removeAllObjects];
	}
    
	[apool release];
	if (needToLoadScene) [self loadScene];
}



-(void)gameOver
{
	[inputController gameOver];
}

- (void)updateModel
{
	// simply call 'update' on all our scene objects
	[inputController updateInterface];
	[sceneObjects makeObjectsPerformSelector:@selector(update)];
	// be sure to clear the events
	[inputController clearEvents];
}

- (void)renderScene
{
	// turn openGL 'on' for this frame
	[openGLView beginDraw];
	
	[self setupLighting];
	// simply call 'render' on all our scene objects
	[sceneObjects makeObjectsPerformSelector:@selector(render)];
	// draw the interface on top of everything
	[inputController renderInterface];
	// finalize this frame
	[openGLView finishDraw];
}
-(void)setupLighting
{
	// cull the unseen faces
	// we use 'front' culling because Cheetah3d exports our models to be compatible
	// with this way
	glEnable(GL_CULL_FACE);
	glCullFace(GL_FRONT);
	
    // Light features
    GLfloat light_ambient[]= { 0.2f, 0.2f, 0.2f, 1.0f };
    GLfloat light_diffuse[]= { 80.0f, 80.0f, 80.0f, 0.0f };
    GLfloat light_specular[]= { 80.0f, 80.0f, 80.0f, 0.0f };
    // Set up light 0
    glLightfv (GL_LIGHT0, GL_AMBIENT, light_ambient);
    glLightfv (GL_LIGHT0, GL_DIFFUSE, light_diffuse);
    glLightfv (GL_LIGHT0, GL_SPECULAR, light_specular);
    
    // // // Material features
    //  GLfloat mat_specular[] = { 0.5, 0.5, 0.5, 1.0 };
    //  GLfloat mat_shininess[] = { 120.0 };
    //  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular);
    //  glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess);
    
    glShadeModel (GL_SMOOTH);
    
	// Place the light up and to the right
    GLfloat light0_position[] = { 50.0, 50.0, 50.0, 1.0 };
    glLightfv(GL_LIGHT0, GL_POSITION, light0_position);
	
	
    // Enable lighting and lights
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    
}



#pragma mark Animation Timer

// these methods are copied over from the EAGLView template

- (void)startAnimation {
	self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];
}

- (void)stopAnimation {
	self.animationTimer = nil;
}

- (void)setAnimationTimer:(NSTimer *)newTimer {
	[animationTimer invalidate];
	animationTimer = newTimer;
}

- (void)setAnimationInterval:(NSTimeInterval)interval {	
	animationInterval = interval;
	if (animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}

#pragma mark dealloc


- (void) dealloc
{
	[self stopAnimation];
	
	[sceneObjects release];
	[objectsToAdd release];
	[objectsToRemove release];
	[inputController release];
	[openGLView release];
//	[collisionController release];
	
	[super dealloc];
}



@end
