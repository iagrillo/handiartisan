$content = Get-Content "handiartisan\lib\main.dart" -Raw

# Add the import
$content = $content -replace "import 'features/wallet/wallet_page.dart';", "import 'features/wallet/wallet_page.dart';`nimport 'features/jobs/jobs_page.dart';"

# Add the route
$content = $content -replace "'/wallet': \(context\) => const WalletPage\(\),", "'/wallet': (context) => const WalletPage(),`n          '/jobs': (context) => const JobsPage(),"

Set-Content -Path "handiartisan\lib\main.dart" -Value $content -NoNewline
