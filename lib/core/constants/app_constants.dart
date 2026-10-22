class AppConstants {
  static const String appName = 'LongWallet';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://rdqagqspiwnsrzexuzcq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkcWFncXNwaXduc3J6ZXh1emNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1OTk4OTcsImV4cCI6MjEwODE3NTg5N30.fKtXYltoOpGA4iu9IJ5xqkHwfAEcblIIs54lQL69A-U';

  // Bank Mapping Codes
  static const Map<String, String> bankPackages = {
    'com.VCB': 'Vietcombank',
    'com.mbmobile': 'MB Bank',
    'vn.com.techcombank.bb.app': 'Techcombank',
    'com.vnpay.bidv': 'BIDV',
    'com.vietinbank.ipay': 'VietinBank',
    'com.mservice.momotransfer': 'MoMo',
    'com.vng.zingpay': 'ZaloPay',
  };
}
