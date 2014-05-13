//
//  IMViewController.m
//  Images
//
//  Created by Tyler Hall on 5/10/14.
//  Copyright (c) 2014 Click On Tyler. All rights reserved.
//

#import "IMViewController.h"
#import "IMImageCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "JTSImageViewController.h"

@interface IMViewController () <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, JTSImageViewControllerInteractionsDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *results;
@property (nonatomic, assign) NSInteger start;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation IMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.results = [NSMutableArray array];

    [self.collectionView registerNib:[UINib nibWithNibName:[[IMImageCollectionViewCell class] description] bundle:nil]
          forCellWithReuseIdentifier:[[IMImageCollectionViewCell class] description]];
 
    [self.searchBar becomeFirstResponder];
}

- (void)fetchImagesWithQuery:(NSString *)query
{
    if(self.isLoading) {
        return;
    }

    self.isLoading = YES;

    NSDictionary *params = @{ @"v" : @"1.0", @"rsz" : @"8", @"q" : query, @"start" : [NSString stringWithFormat:@"%ld", (long)self.start] };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"https://ajax.googleapis.com/ajax/services/search/images" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject isKindOfClass:[NSDictionary class]]) {
            if([responseObject[@"responseData"] isKindOfClass:[NSDictionary class]]) {
                if(responseObject[@"responseData"][@"results"]) {
                    self.results = [self.results arrayByAddingObjectsFromArray:responseObject[@"responseData"][@"results"]];
                    [self.collectionView reloadData];
                }
            }
        }
        self.isLoading = NO;

        if(self.start < 40) {
            self.start += 8;
            [self fetchImagesWithQuery:query];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.isLoading = NO;
    }];
}

#pragma mark -
#pragma mark UISearchBarDelegate
#pragma mark -

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.results = [NSArray array];
    self.start = 0;
    [self.collectionView reloadData];
    [self fetchImagesWithQuery:self.searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark UICollectionView Stuff
#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.results.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IMImageCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[[IMImageCollectionViewCell class] description]
                                                                                     forIndexPath:indexPath];
    if(indexPath.row < self.results.count) {
        NSString *urlString = self.results[indexPath.row][@"tbUrl"];
        [cell.imageView setImageWithURL:[NSURL URLWithString:urlString]];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.imageURL = [NSURL URLWithString:self.results[indexPath.row][@"url"]];
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmedBlurred];
    imageViewer.interactionsDelegate = self;
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSArray *visibleItems = [self.collectionView indexPathsForVisibleItems];
    for(NSInteger i = 0; i < visibleItems.count; i++) {
        NSIndexPath *indexPath = visibleItems[i];
        if(indexPath.row == self.results.count - 1) {
            if(!self.isLoading) {
                self.start += 8;
                [self fetchImagesWithQuery:self.searchBar.text];
            }
        }
    }
}

#pragma mark -
#pragma mark JTSImageViewController Delegate
#pragma mark -

- (void)imageViewerDidLongPress:(JTSImageViewController *)imageViewer
{
    UIImageWriteToSavedPhotosAlbum(imageViewer.image, self, @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), NULL);
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
