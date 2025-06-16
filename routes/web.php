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
