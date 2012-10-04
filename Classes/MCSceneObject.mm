//
//  MCSceneObject.m
//  MCGame
// 
//  Created by ruitaoCC@gmail.com on 1/09/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import "MCSceneObject.h"
#import "MCSceneController.h"
#import "MCInputViewController.h"
#import "MCMesh.h"

#pragma mark Spinny Square mesh



@implementation MCSceneObject

@synthesize translation,rotation,scale,active,mesh,matrix,meshBounds;

- (id) init
{
	self = [super init];
	if (self != nil) {
		translation = MCPointMake(0.0, 0.0, 0.0);
		rotation = MCPointMake(0.0, 0.0, 0.0);
		scale = MCPointMake(1.0, 1.0, 1.0);
		matrix = (CGFloat *) malloc(16 * sizeof(CGFloat));
		active = NO;
		meshBounds = CGRectZero;
		//self.collider = nil;
	}
	return self;
}

-(CGRect) meshBounds
{
	if (CGRectEqualToRect(meshBounds, CGRectZero)) {
		meshBounds = [MCMesh meshBounds:mesh scale:scale];
	}
	return meshBounds;
}
// called once when the object is first created.
-(void)awake
{
}

// called once every frame
-(void)update
{
	glPushMatrix();
	glLoadIdentity();
	
	// move to my position
	glTranslatef(translation.x, translation.y, translation.z);
	
	// rotate
	glRotatef(rotation.x, 1.0f, 0.0f, 0.0f);
	glRotatef(rotation.y, 0.0f, 1.0f, 0.0f);
	glRotatef(rotation.z, 0.0f, 0.0f, 1.0f);
	
	//scale
	glScalef(scale.x, scale.y, scale.z);
	// save the matrix transform
	glGetFloatv(GL_MODELVIEW_MATRIX, matrix);
	//restore the matrix
	glPopMatrix();
	//if (collider != nil) [collider updateCollider:self];   
}

// called once every frame
-(void)render
{
    if (!mesh || !active) return; // if we do not have a mesh, no need to render
	// clear the matrix
	glPushMatrix();
	glLoadIdentity();
	glMultMatrixf(matrix);
	[mesh render];	
	glPopMatrix();}

- (void) dealloc
{
	
	[mesh release];
	//[collider release];
	free(matrix);	
	[super dealloc];

}

@end
