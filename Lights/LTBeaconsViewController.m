//
//  LTBeaconsViewController.m
//  Lights
//
//  Created by Evan Coleman on 3/12/14.
//  Copyright (c) 2014 Evan Coleman. All rights reserved.
//

#import "LTBeaconsViewController.h"
#import <CoreLocation/CoreLocation.h>

static NSString * const LTBeaconUUID = @"E2D56DB8-DFFB-38D2-B06A-D0F5A71096E0";
static NSString * const LTBeaconKey = @"LTBeaconKey";
static NSString * const LTBeaconRegionKey = @"LTBeaconRegionKey";

@interface LTBeaconsViewController () <CLLocationManagerDelegate>

@property (nonatomic) NSArray *beacons;
@property (nonatomic) NSMutableDictionary *beaconsDict;

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation LTBeaconsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Beacons";
        self.locationManager = [[CLLocationManager alloc] init];
        self.beaconsDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager.delegate = self;
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:LTBeaconUUID];
    NSString *identifier = @"net.evancoleman.lights";
    [[LKSession activeSession] queryBeaconsWithBlock:^(NSArray *beacons) {
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        self.beacons = beacons;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.beaconsDict count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSArray *sectionValues = [self.beaconsDict allValues];
    return [[sectionValues objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BeaconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSNumber *sectionKey = [[self.beaconsDict allKeys] objectAtIndex:indexPath.section];
    CLBeacon *beacon = [[self.beaconsDict objectForKey:sectionKey] objectAtIndex:indexPath.row];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"major == %@ AND minor == %@", beacon.major, beacon.minor];
    LKBeacon *b = [[self.beacons filteredArrayUsingPredicate:predicate] firstObject];
    
    cell.textLabel.text = b.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Major: %@, Minor: %@, Acc: %.2fm", beacon.major, beacon.minor, beacon.accuracy];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    NSArray *sectionKeys = [self.beaconsDict allKeys];
    
    NSNumber *sectionKey = [sectionKeys objectAtIndex:section];
    switch([sectionKey integerValue]) {
        case CLProximityImmediate:
            title = @"Immediate";
            break;
            
        case CLProximityNear:
            title = @"Near";
            break;
            
        case CLProximityFar:
            title = @"Far";
            break;
            
        default:
            title = @"Unknown";
            break;
    }
    
    return title;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    [self.beaconsDict removeAllObjects];
    
    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count])
        [self.beaconsDict setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        [self.beaconsDict setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        [self.beaconsDict setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        [self.beaconsDict setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"%@", [error localizedDescription]);
}

@end
