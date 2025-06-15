<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AdminBookingsListController;


// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/admin/customers', [AdminController::class, 'getAllCustomers']);

Route::get('/admin/bookings', [BookingController::class, 'getAllBookingsForAdmin']);

Route::put('/admin/bookings/{id}/status', [BookingController::class, 'updateStatus']);

Route::get('/admin/completed-bookings', [BookingController::class, 'getCompletedBookingsForAdmin']);

Route::put('/admin/completed-bookings/{id}', [BookingController::class, 'updateCompletedBooking']);

Route::get('/admin/bookings/totals', [BookingController::class, 'getBookingTotals']);

// Protected routes (Requires authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/customer', [CustomerController::class, 'getCustomer']);
    Route::put('/customer/update', [CustomerController::class, 'updateCustomer']);
    Route::post('/logout', [AuthController::class, 'logout']);
    // Route to refresh authentication token
    Route::post('/refresh-token', [AuthController::class, 'refreshToken']);

    Route::post('/bookings', [BookingController::class, 'createBooking']);
    Route::get('/bookings', [BookingController::class, 'getBookings']);
    Route::get('/bookings/upcoming', [BookingController::class, 'getUpcomingBookings']);
    Route::put('/bookings/{id}/cancel', [BookingController::class, 'cancelBooking']);
    Route::get('/bookings/availability', [BookingController::class, 'checkAvailability']);
    Route::get('/bookings/completed', [BookingController::class, 'getCompletedBookings']);
});
