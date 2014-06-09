//
//  CoreBridge.h
//  AirBitz
//

#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"


@interface CoreBridge : NSObject

+ (void)loadWallets: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets;
+ (void)reloadWallet: (Wallet *) wallet;
+ (Wallet *)getWallet: (NSString *)walletUUID;
+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;

+ (void)setWalletOrder: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets;
+ (bool)setWalletAttributes: (Wallet *) wallet;

+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions;
+ (bool)storeTransaction: (Transaction *) transaction;

+ (NSString *)formatCurrency: (double) currency;
+ (NSString *)formatCurrency: (double) currency withSymbol:(bool) symbol;
+ (NSString *)formatSatoshi: (int64_t) bitcoin;
+ (NSString *)formatSatoshi: (int64_t) bitcoin withSymbol:(bool) symbol;
+ (int64_t) denominationToSatoshi: (NSString *) amount;
+ (NSString *)conversionString: (int) currencyNumber;
+ (void)logout;
+ (void)startWatchers;
+ (void)stopWatchers;
+ (void)watchAddresses: (NSString *) walletUUID;

@end
