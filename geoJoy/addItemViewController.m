//
//  addItemViewController.m
//  geoJoy
//
//  Created by Jakob Hans Renpening on 22/08/11.
//  Copyright 2011 Claim Soluciones, S.C.P. All rights reserved.
//

#import "addItemViewController.h"

@implementation addItemViewController

@synthesize itemLabel;
@synthesize addDisplayLocationButton;
@synthesize setCategoryButton;
@synthesize loadingViewText;
@synthesize loadingView, categoriesView, mapView, containerView;
@synthesize map;
@synthesize positionToBeSaved;
@synthesize CLController;
@synthesize model;

// Custom, private functions in the backend

-(void)checkForConnection {
    ConnectedClass *connection = [[ConnectedClass alloc] init];
    
    if ([connection connected] == NO) {
        UIAlertView *alertDialog = [[UIAlertView alloc] initWithTitle:@"Internet Connection" message:@"This application requires an internet connection to work properly. Please activate either a WiFi or a cellular data connection." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertDialog show];
        [alertDialog release];
    }
    
    [connection release];
}

-(void)showLoadingViewWithText:(NSString *)text {
    loadingViewText.text = text;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    loadingView.alpha = 0.8;
    [UIView commitAnimations];
}

-(void)dissapearLoadingView {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.7];
    loadingView.alpha = 0;
    [UIView commitAnimations];
}

-(void)loadDbAddLocation {
    [self showLoadingViewWithText:@"Saving item..."];
    if ([model addNewItemWithName:itemLabel.text latitude:positionToBeSaved.coordinate.latitude longitude:positionToBeSaved.coordinate.longitude category:pickerString] == YES) {
        loadingViewText.text = @"Item saved!";
        
        [categoriesPicker selectRow:0 inComponent:0 animated:NO];
        itemLabel.text = @"";
    } else {
        UIAlertView *alertDialog = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"There was a problem adding your location." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertDialog show];
        [alertDialog release];
    }
    
    [self dissapearLoadingView];
}

-(void)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

-(IBAction)toggleToCategories {
    
    if (mapScreenOnTop == NO) {
        [setCategoryButton setTitle:@"Categories" forState:UIControlStateNormal];
        mapScreenOnTop = YES;
        
        [self.itemLabel resignFirstResponder];
        
        [UIView beginAnimations:nil context:self.view];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:containerView cache:YES];
        [containerView bringSubviewToFront:mapView];
        [UIView commitAnimations];
        
    } else {
        [setCategoryButton setTitle:@"Map" forState:UIControlStateNormal];
        mapScreenOnTop = NO;
        
        [self.itemLabel resignFirstResponder];
        
        [UIView beginAnimations:nil context:self.view];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:containerView cache:YES];
        [containerView bringSubviewToFront:categoriesView];
        [UIView commitAnimations];
    }
}

-(IBAction)addCurrentLocation {
    UIAlertView *alertDialog;
    
    if (mapScreenOnTop == NO) {
        [self toggleToCategories];
    }
    
    if ([itemLabel.text isEqualToString:@""]) {
        alertDialog = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"Item needs a label." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertDialog show];
        [alertDialog release];
    } else {
        [self loadDbAddLocation];
    }
}

-(IBAction)updatelocation {
    [self showLoadingViewWithText:@"Locating..."];
    [CLController.locMgr startUpdatingLocation];
    updateLocationButton.enabled = NO;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [categories count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [categories objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    pickerString = [categories objectAtIndex:row];
    pickerValue = row;
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *pinDrop = (MKPinAnnotationView *)[map dequeueReusableAnnotationViewWithIdentifier:@"current"];
    if (pinDrop == nil) {
        pinDrop = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"current"] autorelease];
        pinDrop.pinColor = MKPinAnnotationColorPurple;
        pinDrop.canShowCallout = YES;
        pinDrop.animatesDrop = NO;
    } else {
        pinDrop.annotation = annotation;
    }
    return pinDrop;
}

-(void)locationUpdate:(CLLocation *)location {
    if (location.horizontalAccuracy >= 0) {
        NSArray *annotationsArray = [NSArray arrayWithArray:[map annotations]];
        MKCoordinateRegion mapRegion;
                
        [addDisplayLocationButton setEnabled:TRUE];
        
        mapRegion.center = location.coordinate;
        mapRegion.span.latitudeDelta = 0.005;
        mapRegion.span.longitudeDelta = 0.005;
        
        [map setRegion:mapRegion animated:YES];
        
        if (positionToBeSaved == nil || (positionToBeSaved.coordinate.latitude != location.coordinate.latitude || positionToBeSaved.coordinate.longitude != location.coordinate.longitude)) {
            positionToBeSaved = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
            [map addAnnotation:[[[annotationsController alloc] initWithTitle:@"This is you" subtitle:@"Use the reolad button to update your location." coordinate:location.coordinate] autorelease]];
            if ([annotationsArray count] > 0) {
                [map removeAnnotations:annotationsArray];
            }
            [CLController.locMgr stopUpdatingLocation];
            updateLocationButton.enabled = YES;
            [self dissapearLoadingView];
        }
    }
}

-(void)locationError:(NSError *)error {
    UIAlertView *alertDialog;
    
    [self dissapearLoadingView];
    
    NSString *errorMessage;
    
    if (error.code == kCLErrorDenied) {
        errorMessage = @"The application needs location services to work properly. They are currently disabled for geoJoy.";
    } else if (error.code == kCLErrorLocationUnknown) {
        errorMessage = @"There has been a problem while trying to get your location. Please try again.";
    } else if (error.code == kCLErrorNetwork) {
        errorMessage = @"The location device has returned an error of unavailable or disabled network. Please make sure your location device is working properly.";
    } else {
        errorMessage = @"There has been an unknown error while trying to get your location. Please try again.";
    }
    
    alertDialog = [[UIAlertView alloc] initWithTitle:@"Location Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertDialog show];
    [alertDialog release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

-(void)viewWillAppear:(BOOL)animated {
    [self checkForConnection];
    [super viewWillAppear:animated];
}


- (void)viewDidUnload
{
    [CLController release];
    [model release];
    
    self.mapView = nil;
    self.loadingView = nil;
    self.categoriesView = nil;
    self.containerView = nil;
    
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [self showLoadingViewWithText:@"Locating..."];
    [self.itemLabel setReturnKeyType:UIReturnKeyDone];
    [self.itemLabel addTarget:self
                       action:@selector(textFieldFinished:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    CLController = [[CLLocationController alloc] init];
    CLController.delegate = self;
    
    model = [[dbModel alloc] init];
    
    updateLocationButton.enabled = YES;
    
    mapScreenOnTop = YES;
    
    categories = [[NSArray alloc] initWithObjects:@"Arts & Crafts", @"Education", @"Entertainment", @"Family", @"Food", @"Friends", @"Landscape & View", @"Museum", @"Party", @"Professional", @"Shopping", @"Technology", @"Other", nil];
    
    pickerString = [categories objectAtIndex:0];
    pickerValue = 0;
    
    [super viewDidLoad];
}

-(void)dealloc {
    [itemLabel release];
    [addDisplayLocationButton release];
    [setCategoryButton release];
    [map release];
    [loadingView release];
    [categoriesView release];
    [mapView release];
    [containerView release];
    [categories release];
    [pickerString release];
    [positionToBeSaved release];
    [CLController release];
    [model release];
    [super dealloc];
}

@end