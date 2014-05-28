//
//  TransactionDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "TransactionDetailsViewController.h"
#import "CoreBridge.h"
#import "User.h"
#import "NSDate+Helper.h"
#import "ABC.h"
#import "InfoView.h"
#import "AutoCompleteTextField.h"
#import "CalculatorView.h"
#import "PickerTextView.h"
#import "StylizedTextField.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "Location.h"
#import "CJSONDeserializer.h"
#import "Util.h"
#import "CommonTypes.h"


#define USE_AUTOCOMPLETE_QUERY 0

#define DOLLAR_CURRENCY_NUM	840

#define USE_NAME_TEXTFIELD	1

#define TEXTFIELD_VERTICAL_SPACE_OFFSET	7.0 /* how much space between screen header and textField when textField is scrolled all the way to the top */

@interface TransactionDetailsViewController () <UITextFieldDelegate, InfoViewDelegate, AutoCompleteTextFieldDelegate, CalculatorViewDelegate, DL_URLRequestDelegate, UITableViewDataSource, UITableViewDelegate>
{
	UITextField     *_activeTextField;
	CGRect          _originalFrame;
	CGRect          _originalHeaderFrame;
	CGRect          _originalContentFrame;
	CGRect          _originalScrollableContentFrame;
	NSMutableArray  *_foundBusinessNames;	//list of found names from business search
	NSMutableArray  *_foundContactsArray;	//list of found names from contacts search
	NSArray         *_autoCompleteResults;	//found Contacts and found Businesses all merged together and sorted
	NSArray         *_contactsArray;		//list of all names from contacts
	UITableView     *_autoCompleteTable; //table of autoComplete search results (including address book entries)
}

@property (nonatomic, weak) IBOutlet UIView             *headerView;
@property (nonatomic, weak) IBOutlet UIView             *contentView;
@property (nonatomic, weak) IBOutlet UIView             *scrollableContentView;
@property (nonatomic, weak) IBOutlet UILabel            *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel            *walletLabel;
@property (nonatomic, weak) IBOutlet UILabel            *bitCoinLabel;
@property (nonatomic, weak) IBOutlet UIButton           *advancedDetailsButton;
@property (nonatomic, weak) IBOutlet UIButton           *doneButton;
@property (nonatomic, weak) IBOutlet UITextField        *fiatTextField;
@property (nonatomic, weak) IBOutlet UITextField        *notesTextField;
@property (nonatomic, weak) IBOutlet StylizedTextField  *categoryTextField;
@property (nonatomic, weak) IBOutlet StylizedTextField  *nameTextField;
@property (nonatomic, weak) IBOutlet CalculatorView     *keypadView;
//@property (nonatomic, weak) IBOutlet StylizedTextField *namePickerTextView;
@end

@implementation TransactionDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.contentView];

    // set the keyboard return button based upon mode
    self.nameTextField.returnKeyType = (self.bOldTransaction ? UIReturnKeyDone : UIReturnKeyNext);
    self.categoryTextField.returnKeyType = (self.bOldTransaction ? UIReturnKeyDone : UIReturnKeyNext);
    self.notesTextField.returnKeyType = UIReturnKeyDone;

	[self generateListOfContactNames];
	UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateNormal];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateSelected];
	
	_foundBusinessNames = [[NSMutableArray alloc] init];
    
	self.keypadView.delegate = self;
    self.keypadView.textField = self.fiatTextField;
	
	self.fiatTextField.delegate = self;
	self.fiatTextField.inputView = self.keypadView;
	self.notesTextField.delegate = self;
#if	USE_NAME_TEXTFIELD
	self.nameTextField.delegate = self;
	//self.nameTextField.autoTextFieldDelegate = self;
#else
	//self.namePickerTextView.textField.delegate = self;
	self.namePickerTextView.delegate = self;
	self.namePickerTextView.pickerMaxChoicesVisible = 20;
#endif
	self.categoryTextField.delegate = self;
	
	//self.categoryTextField.autoTextFieldDelegate = self;
	
	/*
	 @property (nonatomic, copy)     NSString        *strID;
	 @property (nonatomic, copy)     NSString        *strWalletUUID;
	 @property (nonatomic, copy)     NSString        *strWalletName;
	 @property (nonatomic, copy)     NSString        *strName;
	 @property (nonatomic, copy)     NSString        *strAddress;
	 @property (nonatomic, strong)   NSDate          *date;
	 @property (nonatomic, assign)   BOOL            bConfirmed;
	 @property (nonatomic, assign)   unsigned int    confirmations;
	 @property (nonatomic, assign)   double          amount;
	 @property (nonatomic, assign)   double          balance;
	 @property (nonatomic, copy)     NSString        *strCategory;
	 @property (nonatomic, copy)     NSString        *strNotes;
	 */
	 
	// self.dateLabel.text = [NSDate stringForDisplayFromDate:self.transaction.date prefixed:NO alwaysDisplayTime:YES];
	
    NSLog(@("%@ %@ %@\n"), self.transaction.strName, self.transaction.strCategory, self.transaction.strNotes);
	self.dateLabel.text = [NSDate stringFromDate:self.transaction.date withFormat:[NSDate timestampFormatString]];
#if	USE_NAME_TEXTFIELD
	self.nameTextField.text = self.transaction.strName;
    //[self.nameTextField setTableBelow:YES];
    self.notesTextField.text = self.transaction.strNotes;
    self.categoryTextField.text = self.transaction.strCategory;
#endif
	#warning TODO Put these in an array here and use it to source the auto-complete tableView  Look at AutoCompleteTextField.m (-searchAutocompleteEntriesWithSubstring) for code that ignores "Transfer:", "Expense:", etc.
	#if 0
	self.categoryTextField.arrayAutoCompleteStrings = [NSArray arrayWithObjects:@"Income:Salary", @"Income:Rent", @"Transfer:Bank Account", @"Transfer:Cash", @"Transfer:Wallet", @"Expense:Dining", @"Expense:Clothing", @"Expense:Computers", @"Expense:Electronics", @"Expense:Education", @"Expense:Entertainment", @"Expense:Rent", @"Expense:Insurance", @"Expense:Medical", @"Expense:Pets", @"Expense:Recreation", @"Expense:Tax", @"Expense:Vacation", @"Expense:Utilities",nil];
	self.categoryTextField.tableAbove = YES;
	#endif
	
	//[self.addressButton setTitle:self.transaction.strAddress forState:UIControlStateNormal];
    self.bitCoinLabel.text = [CoreBridge formatSatoshi:self.transaction.amountSatoshi];

	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
#if USE_NAME_TEXTFIELD
	self.nameTextField.placeholder = NSLocalizedString(@"Payee or Business Name", nil);
    if (!self.bOldTransaction)
    {
        [self.nameTextField becomeFirstResponder];
    }
#else
	
	[self.namePickerTextView setTextFieldObject:[[StylizedTextField alloc] initWithFrame:self.namePickerTextView.textField.frame]];
	self.namePickerTextView.textField.text = self.transaction.strName;
	self.namePickerTextView.textField.placeholder = NSLocalizedString(@"Payee or Business Name", nil);
#endif	
	_originalHeaderFrame = self.headerView.frame;
	_originalContentFrame = self.contentView.frame;
	_originalScrollableContentFrame = self.scrollableContentView.frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

	if (_originalFrame.size.height == 0)
	{
		CGRect frame = self.view.frame;
		frame.origin.x = 0;
		frame.origin.y = 0;
		_originalFrame = frame;
		
		if (_transactionDetailsMode == TD_MODE_SENT)
		{
			self.walletLabel.text = [NSString stringWithFormat:@"From: %@", self.transaction.strWalletName];
		}
		else
		{
			self.walletLabel.text = [NSString stringWithFormat:@"To: %@", self.transaction.strWalletName];
		}
		
        if (self.transaction.amountFiat == 0)
		{
            double currency;
            tABC_Error error;
            ABC_SatoshiToCurrency(self.transaction.amountSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
            self.fiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
        }
		else
		{
            self.fiatTextField.text = [NSString stringWithFormat:@"%.2f", self.transaction.amountFiat];
        }

        // push the calculator keypad to below the bottom of the screen
		frame = self.keypadView.frame;
		frame.origin.y = frame.origin.y + frame.size.height;
		self.keypadView.frame = frame;
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.delegate TransactionDetailsViewControllerDone:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Action Methods

- (IBAction)Done
{
    [self resignAllResponders];

    self.transaction.strName = [self.nameTextField text];
    self.transaction.strNotes = [self.notesTextField text];
    self.transaction.strCategory = [self.categoryTextField text];
    self.transaction.amountFiat = [[self.fiatTextField text] doubleValue];

    [CoreBridge storeTransaction: self.transaction];
	[self.delegate TransactionDetailsViewControllerDone:self];
}

- (IBAction)AdvancedDetails
{
    [self resignAllResponders];

	//spawn infoView
	InfoView *iv = [InfoView CreateWithDelegate:self];
	iv.frame = self.view.bounds;
	
	NSString* path = [[NSBundle mainBundle] pathForResource:@"transactionDetails" ofType:@"html"];
	NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	
	//transaction ID
	content = [content stringByReplacingOccurrencesOfString:@"*1" withString:self.transaction.strID];
	//Total sent
	content = [content stringByReplacingOccurrencesOfString:@"*2" withString:[NSString stringWithFormat:@"BTC %.5f", ABC_SatoshiToBitcoin(self.transaction.amountSatoshi)]];
	//source
	#warning TODO: source and destination addresses are faked for now, so's miner's fee.
	content = [content stringByReplacingOccurrencesOfString:@"*3" withString:@"1.002<BR>1K7iGspRyQsposdKCSbsoXZntsJ7DPNssN<BR>0.0345<BR>1z8fkj4igkh498thgkjERGG23fhD4gGaNSHa<BR>0.2342<BR>1Wfh8d9csf987gT7H6fjkhd0fkj4tkjhf8S4er3"];
	//Destination
	content = [content stringByReplacingOccurrencesOfString:@"*4" withString:@"1M6TCZJTdVX1xGC8iAcQLTDtRKF2zM6M38<BR>1.27059<BR>12HUD1dsrc9dhQgGtWxqy8dAM2XDgvKdzq<BR>0.00001"];
	//Miner Fee
	content = [content stringByReplacingOccurrencesOfString:@"*5" withString:@"0.0001"];
	iv.htmlInfoToDisplay = content;
	[self.view addSubview:iv];
}

#pragma mark - Misc Methods

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(28, 28, 28, 28)]; //top, left, bottom, right
	return stretchable;
}

- (void)scrollContentViewBackToOriginalPosition
{
	[UIView animateWithDuration:0.35
						  delay: 0.0
						options: UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
         self.headerView.frame = _originalHeaderFrame;
         self.contentView.frame = _originalContentFrame;
         self.scrollableContentView.frame = _originalScrollableContentFrame;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
}

- (void)resignAllResponders
{
    [self.notesTextField resignFirstResponder];
    [self.categoryTextField resignFirstResponder];
    [self.nameTextField resignFirstResponder];
    [self.fiatTextField resignFirstResponder];
    [self dismissPayeeTable];
}

#pragma mark - Calculator delegates

- (void)CalculatorDone:(CalculatorView *)calculator
{
	[self.fiatTextField resignFirstResponder];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
    //NSLog(@"calc change. Field now: %@ (%@)", self.fiatTextField.text, calculator.textField.text);
}

#pragma mark - AutoCompleteTextField delegates

- (void)autoCompleteTextFieldDidSelectFromTable:(AutoCompleteTextField *)textField
{
	if(textField == self.nameTextField)
	{
		[self.categoryTextField becomeFirstResponder];
	}
}
/*
#pragma mark PickerTextView delegates

- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
{
	NSLog(@"DID BEGIN EDITING");
	[UIView animateWithDuration:0.35
						  delay: 0.0
						options: UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
		 CGRect frame = originalHeaderFrame;
		 frame.size.height *= 0.6;
		 self.headerView.frame = frame;
		 
		 CGRect contentFrame = originalContentFrame;
		 contentFrame.origin.y = frame.origin.y + frame.size.height;
		 contentFrame.size.height += (frame.size.height - originalHeaderFrame.size.height);
		 self.contentView.frame = contentFrame;
		 
		 CGRect scrollFrame = originalScrollableContentFrame;
		 scrollFrame.origin.y -= (pickerTextView.frame.origin.y - 7.0);
		 self.scrollableContentView.frame = scrollFrame;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
{
	NSLog(@"DID END EDITING");
	[UIView animateWithDuration:0.35
						  delay: 0.0
						options: UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
		 self.headerView.frame = originalHeaderFrame;
		 
		 self.contentView.frame = originalContentFrame;
		 
		 self.scrollableContentView.frame = originalScrollableContentFrame;
	 }
	completion:^(BOOL finished)
	 {
	 }];
}

- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
	NSLog(@"SHOULD RETURN");
	return YES;
}

-(BOOL)pickerTextViewFieldShouldChange:(PickerTextView *)pickerTextView charactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString * searchStr = [pickerTextView.textField.text stringByReplacingCharactersInRange:range withString:string];
    
	//cw if(self.arrayAutoCompleteStrings.count)
	{
	//cw 	autoCompleteResults = self.arrayAutoCompleteStrings;
	}
	//cwelse
	{
		[self kickOffSearchWithString:searchStr];
		
		
    }
	//cw [self searchAutocompleteEntriesWithSubstring:searchStr];
	return YES;
}
*/

#pragma mark - Category Table

-(void)spawnCategoryTableInFrame:(CGRect)frame
{
	CGRect startingFrame = frame;
	startingFrame.size.height = 0;
	_autoCompleteTable = [[UITableView alloc] initWithFrame:startingFrame];
	[self.view addSubview:_autoCompleteTable];
	
	_autoCompleteTable.dataSource = self;
	_autoCompleteTable.delegate = self;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _autoCompleteTable.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 
	 }];
}

#pragma mark - Payee Table

- (void)spawnPayeeTableInFrame:(CGRect)frame
{
	CGRect startingFrame = frame;
	startingFrame.size.height = 0;
	_autoCompleteTable = [[UITableView alloc] initWithFrame:startingFrame];
	[self.view addSubview:_autoCompleteTable];
	
	_autoCompleteTable.dataSource = self;
	_autoCompleteTable.delegate = self;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _autoCompleteTable.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}

- (void)dismissPayeeTable
{
	if (_autoCompleteTable)
	{
		CGRect frame = _autoCompleteTable.frame;
		frame.size.height = 0.0;
		frame.origin.y = frame.origin.y + 100;// (_originalScrollableContentFrame.origin.y - self.scrollableContentView.frame.origin.y);
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 _autoCompleteTable.frame = frame;
		 }
						 completion:^(BOOL finished)
		 {
			 [_autoCompleteTable removeFromSuperview];
			 _autoCompleteTable = nil;
		 }];
	}
}

#pragma mark - UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_autoCompleteResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PayeeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //5.1 you do not need this if you have set SettingsCell as identifier in the storyboard (else you can remove the comments on this code)
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    cell.textLabel.text = [_autoCompleteResults objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor colorWithRed:213.0/255.0 green:237.0/255.0 blue:249.0/255.0 alpha:1.0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.nameTextField.text = [_autoCompleteResults objectAtIndex:indexPath.row];
	
	//dismiss the tableView
	[self dismissPayeeTable];
	[self.nameTextField resignFirstResponder];
	[self.categoryTextField resignFirstResponder];
	/*self.text = [autoCompleteResults objectAtIndex:indexPath.row];
    [self hideTableViewAnimated:YES];
    [self resignFirstResponder];
	if([self.autoTextFieldDelegate respondsToSelector:@selector(autoCompleteTextFieldDidSelectFromTable:)])
	{
		[self.autoTextFieldDelegate autoCompleteTextFieldDidSelectFromTable:self];
	}*/
}

#pragma mark - infoView delegates

-(void)InfoViewFinished:(InfoView *)infoView
{
	[infoView removeFromSuperview];
}

#pragma mark - AutoComplete search

-(void)kickOffSearchWithString:(NSString *)searchStr
{
	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
	NSMutableString *urlString = [[NSMutableString alloc] init];
	
	NSString *searchTerm = [searchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if(searchTerm == nil)
	{
		//there are non ascii characters in the string
		searchTerm = @" ";
		
	}
	//else
	//{
	//searchTerm = searchStr;
	//}
	
#if USE_AUTOCOMPLETE_QUERY
	[urlString appendString:[NSString stringWithFormat:@"%@/autocomplete-business/?term=%@", SERVER_API, searchTerm]];
	
	[self addLocationToQuery:urlString];
	
	if(urlString != (id)[NSNull null])
	{
		NSLog(@"Autocomplete Query: %@", [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
		[[DL_URLServer controller] issueRequestURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
										withParams:nil
										withObject:self
									  withDelegate:self
								acceptableCacheAge:15.0
									   cacheResult:YES];
	}
#else
	[urlString appendString:[NSString stringWithFormat:@"%@/search/?term=%@&radius=1609&sort=1", SERVER_API, searchTerm]];
	
	[self addLocationToQuery:urlString];
	
	if(urlString != (id)[NSNull null])
	{
		NSLog(@"Autocomplete Query: %@", [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
		[[DL_URLServer controller] issueRequestURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
										withParams:nil
										withObject:self
									  withDelegate:self
								acceptableCacheAge:15.0
									   cacheResult:YES];
	}
#endif

	[_foundContactsArray removeAllObjects];
	for(NSString *curString in _contactsArray)
	{
		NSRange substringRange = [curString rangeOfString:searchStr options:NSCaseInsensitiveSearch];
		//
		if(substringRange.length > 1)
		{
			[_foundContactsArray addObject:curString];
		}
		else if (substringRange.location == 0)
		{
			[_foundContactsArray addObject:curString];
		}
	}
	
}

- (void)addLocationToQuery:(NSMutableString *)query
{
	if ([query rangeOfString:@"&ll="].location == NSNotFound)
	{
		CLLocation *location = [Location controller].curLocation;
		if(location) //can be nil if user has locationServices turned off
		{
			NSString *locationString = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
			[query appendFormat:@"&ll=%@", locationString];
		}
	}
	else
	{
		//NSLog(@"string already contains ll");
	}
}

- (void)mergeAutoCompleteResults
{
	NSMutableSet *set = [NSMutableSet setWithArray:_foundContactsArray];
	[set addObjectsFromArray:_foundBusinessNames];
	
	_autoCompleteResults = [[set allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[_autoCompleteTable reloadData];
	//cw self.namePickerTextView.arrayChoices = autoCompleteResults;
}

- (void)generateListOfContactNames
{
    _foundContactsArray = [[NSMutableArray alloc]init];
    
	CFErrorRef error;
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
	
	__block BOOL accessGranted = NO;
	
	if (ABAddressBookRequestAccessWithCompletion != NULL)
	{
		// we're on iOS 6
		dispatch_semaphore_t sema = dispatch_semaphore_create(0);
		
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
												 {
													 accessGranted = granted;
													 dispatch_semaphore_signal(sema);
												 });
		
		dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
		//dispatch_release(sema);
	}
	else
	{
		// we're on iOS 5 or older
		accessGranted = YES;
	}
	
	if (accessGranted)
	{
		CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
		NSMutableArray *allNames = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(people)];
		for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
		{
			ABRecordRef person = CFArrayGetValueAtIndex(people, i);
			
			NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
			NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
			
			
			[allNames addObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
		}
		
		_contactsArray = allNames;
		_autoCompleteResults = allNames; //start autoCompleteResults with something (don't have business names at this point)
		NSLog(@"All Email %@", _contactsArray);
	}
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	
	//NSLog(@"Results download returned: %@", jsonString );
	
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSError *myError;
	NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
	
	
	NSArray *searchResultsArray;
	//NSLog(@"Got search results: %@", [dictFromServer objectForKey:@"results"]);
	searchResultsArray = [[dictFromServer objectForKey:@"results"] mutableCopy];
	
	//build array of business (prune categories out of list)
	[_foundBusinessNames removeAllObjects];
	
	
	for(NSDictionary *dict in searchResultsArray)
	{
#if USE_AUTOCOMPLETE_QUERY
		NSString *type = [dict objectForKey:@"type"];
		if([type isEqualToString:@"business"])
		{
			[foundBusinessNames addObject:[dict objectForKey:@"text"]];
		}
#else
		NSString *name = [dict objectForKey:@"name"];
		if(name && name != (id)[NSNull null])
		{
			[_foundBusinessNames addObject:name];
		}
#endif
	}
	
	if (searchResultsArray.count)
	{
		NSLog(@"Results: %@", _foundBusinessNames);
	}
	else
	{
		NSLog(@"SEARCH RESULTS ARRAY IS EMPTY!");
	}
	//if (([foundContactsArray count] > 0) || (foundBusinessNames.count))
    //{
		//[self showTableViewAnimated:YES];
    //}
	/*else
	 {
	 [self hideTableViewAnimated:YES];
	 }*/
	
	
	[self mergeAutoCompleteResults];
}

#pragma mark - UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	/*if([textField isKindOfClass:[AutoCompleteTextField class]])
     {
     [(AutoCompleteTextField *)textField autoCompleteTextFieldShouldChangeCharactersInRange:range replacementString:string];
     }*/

    if (textField == self.nameTextField)
    {
        [self kickOffSearchWithString:textField.text];
    }
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_activeTextField = textField;

    CGRect scrollFrame = self.scrollableContentView.frame;

    // WARNING: Lots of magic numbers - but we have to make this change quick for the demo
    // Change some of these for iPhone 4

    if (textField == self.nameTextField)
    {
        scrollFrame.origin.y = -30;

        CGRect frame = self.view.bounds;
        frame.origin.y = 100;
        frame.size.height = 252;
        [self spawnPayeeTableInFrame:frame];
    }
    else if (textField == self.categoryTextField)
    {
        scrollFrame.origin.y = -250;
        [self dismissPayeeTable];
    }
    else if (textField == self.notesTextField)
    {
        scrollFrame.origin.y = -90;
        [self dismissPayeeTable];
    }
    else
    {
        scrollFrame.origin.y = _originalScrollableContentFrame.origin.y;
    }

    [UIView animateWithDuration:0.35
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         self.scrollableContentView.frame = scrollFrame;
     }
                     completion:^(BOOL finished)
     {

     }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	/*if([textField isKindOfClass:[AutoCompleteTextField class]])
     {
     [(AutoCompleteTextField *)textField autoCompleteTextFieldShouldReturn];
     }*/

	[textField resignFirstResponder];

	if (textField == self.nameTextField)
	{
		[self dismissPayeeTable];
        if (!self.bOldTransaction)
        {
            [self.categoryTextField becomeFirstResponder];
        }
	}
    else if (textField == self.categoryTextField)
    {
        if (!self.bOldTransaction)
        {
            [self.notesTextField becomeFirstResponder];
        }
    }
    
	return YES;
}

#pragma mark - Keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{

}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self scrollContentViewBackToOriginalPosition];
	_activeTextField = nil;
}

@end
