<?php

use Illuminate\Support\Facades\Route;

// Health check route for Railway
Route::get('/health', function () {
    try {
        $dbStatus = 'unknown';
        $dbError = null;
        
        try {
            \DB::connection()->getPdo();
            $dbStatus = 'connected';
        } catch (\Exception $e) {
            $dbStatus = 'error';
            $dbError = $e->getMessage();
        }
        
        return response()->json([
            'status' => 'ok',
            'timestamp' => now(),
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'environment' => app()->environment(),
            'debug_mode' => config('app.debug'),
            'database' => [
                'status' => $dbStatus,
                'error' => $dbError,
                'connection' => config('database.default'),
                'host' => config('database.connections.mysql.host'),
                'database' => config('database.connections.mysql.database'),
                'port' => config('database.connections.mysql.port')
            ],
            'env_vars' => [
                'MYSQL_HOST' => env('MYSQL_HOST'),
                'MYSQL_DATABASE' => env('MYSQL_DATABASE'),
                'MYSQL_USER' => env('MYSQL_USER'),
                'APP_KEY_SET' => !empty(env('APP_KEY'))
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ], 500);
    }
});

// Debug route to catch main page errors
Route::get('/debug', function () {
    try {
        // Test basic Laravel functionality
        $tests = [
            'config_loaded' => !empty(config('app.name')),
            'env_file' => file_exists(base_path('.env')),
            'storage_writable' => is_writable(storage_path()),
            'bootstrap_cache_writable' => is_writable(bootstrap_path('cache')),
            'view_path_exists' => file_exists(resource_path('views/welcome.blade.php')),
            'app_key_set' => !empty(config('app.key')),
        ];
        
        return response()->json([
            'status' => 'debug_info',
            'tests' => $tests,
            'errors' => array_keys(array_filter($tests, fn($v) => !$v))
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'debug_error',
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ], 500);
    }
});

// Route::get('/', function () {
//     return view('welcome');
// });

// Route::get('/{any}', function () {
//     return view('welcome'); // Ensure 'app' is the correct Blade template for Vue
// })->where('any', '.*');
Route::get('/login', function () {
    return view('login');
})->name('login.form');

// Web routes
Route::get('/{any}', function () {
    return view('welcome'); // This serves your Vue SPA
})->where('any', '^(?!api).*$'); // This pattern excludes routes starting with "api"

// Simple error test route
Route::get('/test', function () {
    try {
        // Force show all errors
        ini_set('display_errors', 1);
        error_reporting(E_ALL);
        
        return response()->json([
            'status' => 'test_success',
            'message' => 'Basic route is working',
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'timestamp' => now()
        ]);
    } catch (\Throwable $e) {
        return response()->json([
            'status' => 'test_error',
            'error' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ], 500);
    }
});

// Manual migration route (for debugging)
Route::get('/migrate', function () {
    // Force show all errors
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
    
    $output = [];
    $errors = [];
    
    try {
        $output[] = "=== MIGRATION DEBUG START ===";
        $output[] = "PHP Version: " . PHP_VERSION;
        $output[] = "Laravel Version: " . app()->version();
        $output[] = "Environment: " . app()->environment();
        $output[] = "Debug Mode: " . (config('app.debug') ? 'true' : 'false');
        
        // Check basic Laravel setup
        $output[] = "--- Basic Laravel Checks ---";
        $output[] = "App Key Set: " . (!empty(config('app.key')) ? 'YES' : 'NO');
        $output[] = "Database Config: " . config('database.default');
        
        // Check environment variables
        $output[] = "--- Environment Variables ---";
        $output[] = "MYSQL_HOST: " . (env('MYSQL_HOST') ?: 'NOT SET');
        $output[] = "MYSQL_DATABASE: " . (env('MYSQL_DATABASE') ?: 'NOT SET');
        $output[] = "MYSQL_USER: " . (env('MYSQL_USER') ?: 'NOT SET');
        $output[] = "MYSQL_PASSWORD: " . (!empty(env('MYSQL_PASSWORD')) ? 'SET' : 'NOT SET');
        
        // Test raw database connection
        $output[] = "--- Testing Database Connection ---";
        try {
            $host = env('MYSQL_HOST');
            $port = env('MYSQL_PORT', 3306);
            $database = env('MYSQL_DATABASE');
            $username = env('MYSQL_USER');
            $password = env('MYSQL_PASSWORD');
            
            if (!$host || !$database || !$username) {
                throw new \Exception("Missing database credentials: host=$host, db=$database, user=$username");
            }
            
            $pdo = new \PDO("mysql:host=$host;port=$port;dbname=$database", $username, $password, [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION
            ]);
            $output[] = "✓ Raw PDO connection successful";
            
            // Test Laravel database connection
            \DB::connection()->getPdo();
            $output[] = "✓ Laravel database connection successful";
            
        } catch (\Exception $e) {
            $errors[] = "Database connection failed: " . $e->getMessage();
            $output[] = "✗ Database connection failed: " . $e->getMessage();
        }
        
        // Only proceed with migrations if database is connected
        if (empty($errors)) {
            $output[] = "--- Running Migrations ---";
            
            // Check if migrations table exists
            try {
                \Artisan::call('migrate:status');
                $output[] = "Migration status check successful";
            } catch (\Exception $e) {
                $output[] = "Migration status failed (normal for first run): " . $e->getMessage();
            }
            
            // Run migrations
            try {
                \Artisan::call('migrate', ['--force' => true, '--verbose' => true]);
                $migrateOutput = \Artisan::output();
                $output[] = "Migration command executed";
                $output[] = "Migration output: " . $migrateOutput;
            } catch (\Exception $e) {
                $errors[] = "Migration failed: " . $e->getMessage();
                $output[] = "✗ Migration failed: " . $e->getMessage();
            }
        }
        
        $output[] = "=== MIGRATION DEBUG END ===";
        
        return response()->json([
            'status' => empty($errors) ? 'success' : 'partial_success',
            'errors' => $errors,
            'output' => $output,
            'timestamp' => now()
        ]);
        
    } catch (\Throwable $e) {
        $errorDetails = [
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => explode("\n", $e->getTraceAsString())
        ];
        
        return response()->json([
            'status' => 'fatal_error',
            'error' => $errorDetails,
            'output' => $output,
            'timestamp' => now()
        ], 500);
    }
});
